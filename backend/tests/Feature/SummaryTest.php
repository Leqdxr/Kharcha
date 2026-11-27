<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SummaryTest extends TestCase
{
    use RefreshDatabase;

    private function addExpense(User $user, string $date, float $amount, string $category = 'Food'): void
    {
        $user->expenses()->create([
            'title' => 'Item',
            'amount' => $amount,
            'category' => $category,
            'date' => $date,
        ]);
    }

    public function test_summary_totals_for_a_month(): void
    {
        $user = User::factory()->create(['monthly_budget' => 20000]);
        $this->addExpense($user, '2026-11-01', 100, 'Food');
        $this->addExpense($user, '2026-11-30', 50.5, 'Food');
        $this->addExpense($user, '2026-11-15', 300, 'Bills');
        $this->addExpense($user, '2026-11-10', 20, 'Travel');
        $this->addExpense($user, '2026-10-31', 200, 'Other');
        $this->addExpense($user, '2026-10-01', 25, 'Food');
        $this->addExpense($user, '2026-12-01', 999, 'Food');
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/summary?month=2026-11')->assertOk();

        $this->assertSame('2026-11', $response->json('month'));
        $this->assertEquals(470.5, $response->json('total'));
        $this->assertSame(4, $response->json('count'));
        $this->assertSame('2026-10', $response->json('previous_month'));
        $this->assertEquals(225, $response->json('previous_total'));
        $this->assertSame(20000, $response->json('budget'));
        $this->assertSame(['Bills', 'Food', 'Travel'], $response->json('by_category.*.category'));
        $this->assertEquals([300, 150.5, 20], $response->json('by_category.*.total'));
    }

    public function test_summary_ignores_other_users_expenses(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create(['monthly_budget' => 5000]);
        $this->addExpense($user, '2026-11-05', 100);
        $this->addExpense($other, '2026-11-05', 5000, 'Bills');
        $this->addExpense($other, '2026-10-05', 700);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/summary?month=2026-11')->assertOk();

        $this->assertEquals(100, $response->json('total'));
        $this->assertSame(1, $response->json('count'));
        $this->assertEquals(0, $response->json('previous_total'));
        $this->assertNull($response->json('budget'));
        $this->assertSame(['Food'], $response->json('by_category.*.category'));
    }

    public function test_empty_month_returns_zeros(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/summary?month=2026-11')
            ->assertOk()
            ->assertJsonPath('count', 0)
            ->assertJsonPath('by_category', []);
    }

    public function test_summary_defaults_to_current_month(): void
    {
        // The 31st checks that the previous month doesn't overflow (Mar 31 - 1 month must be February).
        $this->travelTo('2027-03-31 12:00:00');
        $user = User::factory()->create();
        $this->addExpense($user, '2027-03-31', 80);
        $this->addExpense($user, '2027-02-28', 40);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/summary')->assertOk();

        $this->assertSame('2027-03', $response->json('month'));
        $this->assertSame('2027-02', $response->json('previous_month'));
        $this->assertEquals(80, $response->json('total'));
        $this->assertEquals(40, $response->json('previous_total'));
    }

    public function test_summary_validates_month(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/summary?month=2026-1')->assertUnprocessable()->assertJsonValidationErrors('month');
    }

    public function test_safe_to_spend_for_the_current_month(): void
    {
        // 27 November: 4 days left including today.
        $this->travelTo('2026-11-27 12:00:00');
        $user = User::factory()->create(['monthly_budget' => 20000]);
        $this->addExpense($user, '2026-11-10', 10495);
        Sanctum::actingAs($user);

        $this->getJson('/api/summary')
            ->assertOk()
            ->assertJsonPath('days_left', 4)
            ->assertJsonPath('safe_to_spend', 2376);
    }

    public function test_safe_to_spend_on_the_last_day_and_when_over_budget(): void
    {
        $this->travelTo('2026-11-30 12:00:00');
        $user = User::factory()->create(['monthly_budget' => 5000]);
        $this->addExpense($user, '2026-11-10', 4000);
        Sanctum::actingAs($user);

        $this->getJson('/api/summary')->assertJsonPath('days_left', 1)->assertJsonPath('safe_to_spend', 1000);

        $this->addExpense($user, '2026-11-30', 2000);
        $this->getJson('/api/summary')->assertJsonPath('safe_to_spend', 0);
    }

    public function test_safe_to_spend_is_null_without_a_budget_or_for_other_months(): void
    {
        $this->travelTo('2026-11-27 12:00:00');
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/summary')->assertJsonPath('days_left', 4)->assertJsonPath('safe_to_spend', null);

        $user->update(['monthly_budget' => 20000]);
        $this->getJson('/api/summary?month=2026-10')
            ->assertJsonPath('days_left', null)
            ->assertJsonPath('safe_to_spend', null);
    }
}
