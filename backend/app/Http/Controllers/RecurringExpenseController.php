<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\RecurringExpense;
use App\Services\RecurringExpenses;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\ValidationException;

class RecurringExpenseController extends Controller
{
    /**
     * Rules sorted by the next bill first.
     */
    public function index(Request $request): JsonResponse
    {
        return response()->json($request->user()->recurringExpenses()->orderBy('next_date')->orderBy('id')->get());
    }

    /**
     * Repeat an existing expense every month on the same day.
     */
    public function store(Request $request, RecurringExpenses $recurring): JsonResponse
    {
        $data = $request->validate(['expense_id' => 'required|integer|exists:expenses,id']);

        $expense = Expense::findOrFail($data['expense_id']);
        $this->authorizeOwner($request, $expense);
        if ($expense->recurring_expense_id) {
            throw ValidationException::withMessages(['expense_id' => 'This expense already repeats.']);
        }

        $rule = $request->user()->recurringExpenses()->make($expense->only(['title', 'amount', 'category', 'payment_method']));
        $rule->day_of_month = $expense->date->day;
        $rule->next_date = $rule->dateInMonthAfter($expense->date);
        $rule->save();
        $expense->update(['recurring_expense_id' => $rule->id]);

        // An expense dated in an earlier month may already have bills due.
        $recurring->createDue($request->user());

        return response()->json($rule->refresh(), 201);
    }

    /**
     * Stop repeating. Expenses already created stay.
     */
    public function destroy(Request $request, RecurringExpense $recurringExpense): Response
    {
        $this->authorizeOwner($request, $recurringExpense);

        $recurringExpense->delete();

        return response()->noContent();
    }
}
