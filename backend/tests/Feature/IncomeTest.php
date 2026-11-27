<?php

namespace Tests\Feature;

use App\Models\Income;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class IncomeTest extends TestCase
{
    use RefreshDatabase;

    private function incomeFor(User $user, array $attributes = []): Income
    {
        return $user->incomes()->create($attributes + [
            'title' => 'Acme Pvt Ltd',
            'amount' => 100000,
            'type' => 'salary',
            'tds_amount' => 9000,
            'date' => '2026-08-15',
        ]);
    }

    public function test_user_can_add_an_income(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/incomes', [
            'title' => 'Client A',
            'amount' => 50000,
            'type' => 'service_pan',
            'tds_amount' => 7500,
            'date' => '2026-09-01',
            'note' => 'Website',
        ])->assertCreated()
            ->assertJsonPath('type', 'service_pan')
            ->assertJsonPath('tds_amount', 7500)
            ->assertJsonPath('date', '2026-09-01');

        $this->assertDatabaseHas('incomes', ['user_id' => $user->id, 'title' => 'Client A']);
    }

    public function test_list_update_and_delete_own_incomes(): void
    {
        $user = User::factory()->create();
        $income = $this->incomeFor($user);
        $this->incomeFor(User::factory()->create());
        Sanctum::actingAs($user);

        $this->getJson('/api/incomes')->assertOk()->assertJsonCount(1)->assertJsonPath('0.id', $income->id);

        $this->putJson("/api/incomes/{$income->id}", [
            'title' => 'Acme',
            'amount' => 120000,
            'type' => 'salary',
            'tds_amount' => 10000,
            'date' => '2026-08-15',
        ])->assertOk()->assertJsonPath('amount', 120000);

        $this->deleteJson("/api/incomes/{$income->id}")->assertNoContent();
        $this->assertDatabaseMissing('incomes', ['id' => $income->id]);
    }

    public function test_user_cannot_touch_someone_elses_income(): void
    {
        $income = $this->incomeFor(User::factory()->create());
        Sanctum::actingAs(User::factory()->create());

        $this->putJson("/api/incomes/{$income->id}", [
            'title' => 'X', 'amount' => 1, 'type' => 'rent', 'tds_amount' => 0, 'date' => '2026-08-01',
        ])->assertForbidden();
        $this->deleteJson("/api/incomes/{$income->id}")->assertForbidden();
        $this->assertDatabaseHas('incomes', ['id' => $income->id]);
    }

    public function test_income_is_validated(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/incomes', [
            'title' => '',
            'amount' => 1000,
            'type' => 'lottery',
            'tds_amount' => 2000,
            'date' => 'soon',
            'note' => str_repeat('a', 256),
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['title', 'type', 'tds_amount', 'date', 'note']);
    }

    public function test_refund_case_with_final_income_excluded(): void
    {
        $user = User::factory()->create();
        // Two months of salary: average 1,00,000 a month with 9,000 TDS.
        $this->incomeFor($user, ['date' => '2026-08-15']);
        $this->incomeFor($user, ['date' => '2026-09-15']);
        $this->incomeFor($user, ['title' => 'Client', 'amount' => 50000, 'type' => 'service_pan', 'tds_amount' => 7500, 'date' => '2026-10-01']);
        // Final withholding: not taxable, not adjustable.
        $this->incomeFor($user, ['title' => 'Bank', 'amount' => 10000, 'type' => 'interest', 'tds_amount' => 600, 'date' => '2026-10-10']);
        // Outside FY 2083/84.
        $this->incomeFor($user, ['date' => '2026-07-16', 'amount' => 999999, 'tds_amount' => 0]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/tax/summary')->assertOk();

        // Taxable = 12,00,000 + 50,000. Tax = 1% of 10,00,000 + 10% of 2,50,000.
        $this->assertEquals(1200000, $response->json('projected_salary'));
        $this->assertEquals(1250000, $response->json('taxable_income'));
        $this->assertEquals(35000, $response->json('estimated_tax'));
        $this->assertEquals(2.8, $response->json('effective_rate'));
        $this->assertEquals([10000, 25000, 0, 0, 0], $response->json('slabs.*.tax'));
        $this->assertEquals([1000000, 250000, 0, 0, 0], $response->json('slabs.*.taxable'));
        // 9,000 x 12 + 7,500.
        $this->assertEquals(115500, $response->json('adjustable_tds_year_end'));
        $this->assertEquals(25500, $response->json('tds_so_far'));
        $this->assertEquals(600, $response->json('final_tds'));
        $this->assertEquals(80500, $response->json('result'));
        $this->assertEquals(260000, $response->json('totals.gross'));
        $this->assertEquals(10000, $response->json('totals.final'));
        $this->assertSame(2, $response->json('totals.salary_months'));
        $this->assertSame('2083/84', $response->json('fiscal_year.label'));
    }

    public function test_ssf_contributor_skips_the_first_slab(): void
    {
        $user = User::factory()->create(['ssf_contributor' => true]);
        $this->incomeFor($user, ['date' => '2026-08-15']);
        $this->incomeFor($user, ['date' => '2026-09-15']);
        $this->incomeFor($user, ['title' => 'Client', 'amount' => 50000, 'type' => 'service_pan', 'tds_amount' => 7500, 'date' => '2026-10-01']);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/tax/summary')->assertOk();

        $this->assertTrue($response->json('slabs.0.waived'));
        $this->assertEquals(0, $response->json('slabs.0.tax'));
        $this->assertEquals(25000, $response->json('estimated_tax'));
        $this->assertEquals(90500, $response->json('result'));
    }

    public function test_owe_case(): void
    {
        $user = User::factory()->create();
        $this->incomeFor($user, ['amount' => 200000, 'tds_amount' => 5000]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/tax/summary')->assertOk();

        // 24,00,000: 10,000 + 50,000 + 1,80,000.
        $this->assertEquals(240000, $response->json('estimated_tax'));
        $this->assertEquals(60000, $response->json('adjustable_tds_year_end'));
        $this->assertEquals(-180000, $response->json('result'));
    }

    public function test_every_slab_is_used_for_high_income(): void
    {
        $user = User::factory()->create();
        $this->incomeFor($user, ['amount' => 5000000, 'type' => 'rent', 'tds_amount' => 500000]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/tax/summary')->assertOk();

        $this->assertEquals([10000, 50000, 200000, 405000, 290000], $response->json('slabs.*.tax'));
        $this->assertEquals(955000, $response->json('estimated_tax'));
        $this->assertEquals(-455000, $response->json('result'));
    }

    public function test_summary_with_no_income_is_all_zero(): void
    {
        $user = User::factory()->create();
        $this->incomeFor(User::factory()->create());
        Sanctum::actingAs($user);

        $this->getJson('/api/tax/summary')
            ->assertOk()
            ->assertJsonPath('estimated_tax', 0)
            ->assertJsonPath('result', 0)
            ->assertJsonPath('types.interest.final', true);
    }
}
