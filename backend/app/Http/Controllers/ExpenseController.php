<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\User;
use App\Services\RecurringExpenses;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

class ExpenseController extends Controller
{
    public function index(Request $request, RecurringExpenses $recurring): JsonResponse
    {
        $request->validate(['month' => 'nullable|date_format:Y-m']);

        $recurring->createDue($request->user());

        $expenses = $request->user()->expenses()
            ->when($request->query('month'), fn ($query, $month) => $query->inMonth(Carbon::parse($month.'-01')))
            ->orderByDesc('date')
            ->orderByDesc('id')
            ->get();

        return response()->json($expenses);
    }

    public function store(Request $request): JsonResponse
    {
        $expense = $request->user()->expenses()->create($this->validateExpense($request));

        // Reload so every column is in the response (e.g. recurring_expense_id = null).
        return response()->json($expense->refresh(), 201);
    }

    public function update(Request $request, Expense $expense): JsonResponse
    {
        $this->authorizeOwner($request, $expense);

        $expense->update($this->validateExpense($request));

        return response()->json($expense);
    }

    public function destroy(Request $request, Expense $expense): Response
    {
        $this->authorizeOwner($request, $expense);

        $expense->delete();

        // Deleting the last expense of a monthly repeat stops the repeat too.
        $rule = $expense->recurringExpense;
        if ($rule && ! $rule->expenses()->exists()) {
            $rule->delete();
        }

        return response()->noContent();
    }

    private function validateExpense(Request $request): array
    {
        return $request->validate([
            'title' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0',
            'category' => ['required', Rule::in(Expense::CATEGORIES)],
            'payment_method' => ['nullable', Rule::in(User::PAYMENT_METHODS)],
            'date' => 'required|date',
            'note' => 'nullable|string|max:255',
        ]);
    }
}
