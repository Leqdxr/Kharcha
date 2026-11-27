<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ExpenseTest extends TestCase
{
    use RefreshDatabase;

    private function expenseFor(User $user, array $attributes = []): Expense
    {
        return $user->expenses()->create($attributes + [
            'title' => 'Groceries',
            'amount' => 450,
            'category' => 'Food',
            'date' => '2026-11-20',
        ]);
    }

    public function test_user_can_create_an_expense_with_a_note(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/expenses', [
            'title' => 'Bus',
            'amount' => 35.5,
            'category' => 'Travel',
            'date' => '2026-11-22',
            'note' => 'To college',
        ])->assertCreated()
            ->assertJsonPath('title', 'Bus')
            ->assertJsonPath('amount', 35.5)
            ->assertJsonPath('date', '2026-11-22')
            ->assertJsonPath('note', 'To college');

        $this->assertDatabaseHas('expenses', ['user_id' => $user->id, 'title' => 'Bus', 'note' => 'To college']);
    }

    public function test_note_is_optional(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/expenses', [
            'title' => 'Bus',
            'amount' => 35,
            'category' => 'Travel',
            'date' => '2026-11-22',
        ])->assertCreated()->assertJsonPath('note', null);
    }

    public function test_payment_method_is_saved_and_validated(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $expense = [
            'title' => 'Momo',
            'amount' => 180,
            'category' => 'Food',
            'date' => '2026-11-22',
        ];

        $this->postJson('/api/expenses', $expense + ['payment_method' => 'esewa'])
            ->assertCreated()
            ->assertJsonPath('payment_method', 'esewa');
        $this->postJson('/api/expenses', $expense)->assertCreated()->assertJsonPath('payment_method', null);
        $this->postJson('/api/expenses', $expense + ['payment_method' => 'paypal'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('payment_method');
    }

    public function test_list_returns_only_own_expenses_newest_first(): void
    {
        $user = User::factory()->create();
        $older = $this->expenseFor($user, ['date' => '2026-10-01']);
        $newer = $this->expenseFor($user, ['date' => '2026-11-15']);
        $this->expenseFor(User::factory()->create());
        Sanctum::actingAs($user);

        $this->getJson('/api/expenses')
            ->assertOk()
            ->assertJsonCount(2)
            ->assertJsonPath('0.id', $newer->id)
            ->assertJsonPath('1.id', $older->id);
    }

    public function test_user_can_update_own_expense(): void
    {
        $user = User::factory()->create();
        $expense = $this->expenseFor($user);
        Sanctum::actingAs($user);

        $this->putJson("/api/expenses/{$expense->id}", [
            'title' => 'Electricity',
            'amount' => 1200,
            'category' => 'Bills',
            'date' => '2026-11-21',
            'note' => 'November bill',
        ])->assertOk()->assertJsonPath('title', 'Electricity')->assertJsonPath('note', 'November bill');

        $this->assertDatabaseHas('expenses', ['id' => $expense->id, 'category' => 'Bills', 'note' => 'November bill']);
    }

    public function test_user_can_delete_own_expense(): void
    {
        $user = User::factory()->create();
        $expense = $this->expenseFor($user);
        Sanctum::actingAs($user);

        $this->deleteJson("/api/expenses/{$expense->id}")->assertNoContent();

        $this->assertDatabaseMissing('expenses', ['id' => $expense->id]);
    }

    public function test_user_cannot_change_someone_elses_expense(): void
    {
        $expense = $this->expenseFor(User::factory()->create());
        Sanctum::actingAs(User::factory()->create());

        $this->putJson("/api/expenses/{$expense->id}", [
            'title' => 'Hacked',
            'amount' => 1,
            'category' => 'Other',
            'date' => '2026-11-21',
        ])->assertForbidden();
        $this->deleteJson("/api/expenses/{$expense->id}")->assertForbidden();

        $this->assertDatabaseHas('expenses', ['id' => $expense->id, 'title' => 'Groceries']);
    }

    public function test_create_validates_input(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/expenses', [
            'title' => '',
            'amount' => -5,
            'category' => 'Shopping',
            'date' => 'not-a-date',
            'note' => str_repeat('a', 256),
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['title', 'amount', 'category', 'date', 'note']);
    }

    public function test_month_filter_includes_first_and_last_day_only(): void
    {
        $user = User::factory()->create();
        $this->expenseFor($user, ['title' => 'Oct 31', 'date' => '2026-10-31']);
        $this->expenseFor($user, ['title' => 'Nov 1', 'date' => '2026-11-01']);
        $this->expenseFor($user, ['title' => 'Nov 30', 'date' => '2026-11-30']);
        $this->expenseFor($user, ['title' => 'Dec 1', 'date' => '2026-12-01']);
        $this->expenseFor(User::factory()->create(), ['title' => 'Other user', 'date' => '2026-11-15']);
        Sanctum::actingAs($user);

        $titles = $this->getJson('/api/expenses?month=2026-11')->assertOk()->json('*.title');

        $this->assertSame(['Nov 30', 'Nov 1'], $titles);
    }

    public function test_month_filter_handles_february(): void
    {
        $user = User::factory()->create();
        $this->expenseFor($user, ['title' => 'Feb 28', 'date' => '2027-02-28']);
        $this->expenseFor($user, ['title' => 'Mar 1', 'date' => '2027-03-01']);
        Sanctum::actingAs($user);

        $this->getJson('/api/expenses?month=2027-02')->assertOk()->assertJsonCount(1)->assertJsonPath('0.title', 'Feb 28');
    }

    public function test_month_filter_must_be_year_and_month(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/expenses?month=11-2026')->assertUnprocessable()->assertJsonValidationErrors('month');
        $this->getJson('/api/expenses?month=2026-13')->assertUnprocessable()->assertJsonValidationErrors('month');
    }
}
