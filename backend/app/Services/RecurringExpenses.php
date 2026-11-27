<?php

namespace App\Services;

use App\Models\RecurringExpense;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class RecurringExpenses
{
    /**
     * Create the expense for every rule whose next_date is today or earlier,
     * moving next_date forward a month each time. Safe to run again: the rule
     * row is locked and each date is only created once.
     */
    public function createDue(User $user): void
    {
        $today = Carbon::today();
        $dueIds = $user->recurringExpenses()->whereDate('next_date', '<=', $today)->pluck('id');

        foreach ($dueIds as $id) {
            DB::transaction(function () use ($id, $today, $user) {
                $rule = RecurringExpense::lockForUpdate()->find($id);

                while ($rule && $rule->next_date->lte($today)) {
                    $user->expenses()->firstOrCreate(
                        ['recurring_expense_id' => $rule->id, 'date' => $rule->next_date->toDateString()],
                        $rule->only(['title', 'amount', 'category', 'payment_method']),
                    );
                    $rule->next_date = $rule->dateInMonthAfter($rule->next_date);
                }

                $rule?->save();
            });
        }
    }
}
