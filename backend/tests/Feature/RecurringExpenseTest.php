<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RecurringExpenseTest extends TestCase
{
    use RefreshDatabase;

    private function expenseFor(User $user, string $date): Expense
    {
        return $user->expenses()->create([
            'title' => 'Internet bill',
            'amount' => 1500,
            'category' => 'Bills',
            'payment_method' => 'mobile_banking',
            'date' => $date,
        ]);
    }

    public function test_repeating_an_expense_creates_a_rule_for_next_month(): void
    {
        $this->travelTo('2026-11-27 09:00:00');
        $user = User::factory()->create();
        $expense = $this->expenseFor($user, '2026-11-05');
        Sanctum::actingAs($user);

        $this->postJson('/api/recurring-expenses', ['expense_id' => $expense->id])
            ->assertCreated()
            ->assertJsonPath('title', 'Internet bill')
            ->assertJsonPath('payment_method', 'mobile_banking')
            ->assertJsonPath('day_of_month', 5)
            ->assertJsonPath('next_date', '2026-12-05');

        $this->assertNotNull($expense->fresh()->recurring_expense_id);
        $this->getJson('/api/expenses')->assertJsonCount(1)->assertJsonPath('0.recurring_expense_id', $expense->fresh()->recurring_expense_id);
    }

    public function test_due_bills_are_created_once_when_listing_expenses(): void
    {
        $this->travelTo('2026-11-27 09:00:00');
        $user = User::factory()->create();
        $expense = $this->expenseFor($user, '2026-09-05');
        Sanctum::actingAs($user);

        // October and November are already due.
        $rule = $this->postJson('/api/recurring-expenses', ['expense_id' => $expense->id])
            ->assertCreated()
            ->assertJsonPath('next_date', '2026-12-05');

        $this->getJson('/api/expenses')->assertOk()->assertJsonCount(3);
        $this->getJson('/api/expenses')->assertOk()->assertJsonCount(3);
        $this->assertSame(
            ['2026-09-05', '2026-10-05', '2026-11-05'],
            $user->expenses()->orderBy('date')->pluck('date')->map->format('Y-m-d')->all(),
        );
        $this->assertSame(3, Expense::where('recurring_expense_id', $rule->json('id'))->count());

        // On 5 December the next one appears, still only once.
        $this->travelTo('2026-12-05 08:00:00');
        $this->getJson('/api/expenses')->assertJsonCount(4)->assertJsonPath('0.date', '2026-12-05');
        $this->getJson('/api/expenses')->assertJsonCount(4);
        $this->assertSame('2027-01-05', $user->recurringExpenses()->first()->next_date->format('Y-m-d'));
    }

    public function test_day_31_falls_back_to_the_last_day_of_short_months(): void
    {
        $this->travelTo('2027-01-31 09:00:00');
        $user = User::factory()->create();
        $expense = $this->expenseFor($user, '2027-01-31');
        Sanctum::actingAs($user);

        $this->postJson('/api/recurring-expenses', ['expense_id' => $expense->id])->assertJsonPath('next_date', '2027-02-28');

        $this->travelTo('2027-03-31 09:00:00');
        $this->getJson('/api/expenses?month=2027-03')->assertJsonCount(1)->assertJsonPath('0.date', '2027-03-31');
        $this->getJson('/api/expenses?month=2027-02')->assertJsonCount(1)->assertJsonPath('0.date', '2027-02-28');
        $this->assertSame('2027-04-30', $user->recurringExpenses()->first()->next_date->format('Y-m-d'));
    }

    public function test_list_and_stop_repeating(): void
    {
        $this->travelTo('2026-11-27 09:00:00');
        $user = User::factory()->create();
        $expense = $this->expenseFor($user, '2026-11-20');
        $other = $this->expenseFor(User::factory()->create(), '2026-11-20');
        Sanctum::actingAs($user);

        $id = $this->postJson('/api/recurring-expenses', ['expense_id' => $expense->id])->json('id');
        $this->getJson('/api/recurring-expenses')->assertOk()->assertJsonCount(1)->assertJsonPath('0.id', $id);

        $this->deleteJson("/api/recurring-expenses/{$id}")->assertNoContent();

        $this->getJson('/api/recurring-expenses')->assertJsonCount(0);
        $this->assertNull($expense->fresh()->recurring_expense_id);
        $this->assertModelExists($expense);
        $this->assertModelExists($other);
    }

    public function test_user_cannot_repeat_or_stop_someone_elses_bill(): void
    {
        $owner = User::factory()->create();
        $expense = $this->expenseFor($owner, '2026-11-20');
        Sanctum::actingAs($owner);
        $id = $this->postJson('/api/recurring-expenses', ['expense_id' => $expense->id])->json('id');
        $otherExpense = $this->expenseFor($owner, '2026-11-21');

        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/recurring-expenses', ['expense_id' => $otherExpense->id])->assertForbidden();
        $this->deleteJson("/api/recurring-expenses/{$id}")->assertForbidden();
        $this->getJson('/api/recurring-expenses')->assertJsonCount(0);
        $this->assertSame(1, $owner->recurringExpenses()->count());
    }

    public function test_store_is_validated(): void
    {
        $user = User::factory()->create();
        $expense = $this->expenseFor($user, '2026-11-20');
        Sanctum::actingAs($user);

        $this->postJson('/api/recurring-expenses', [])->assertUnprocessable()->assertJsonValidationErrors('expense_id');
        $this->postJson('/api/recurring-expenses', ['expense_id' => 99999])->assertUnprocessable()->assertJsonValidationErrors('expense_id');

        $this->postJson('/api/recurring-expenses', ['expense_id' => $expense->id])->assertCreated();
        $this->postJson('/api/recurring-expenses', ['expense_id' => $expense->id])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('expense_id');
    }
}
