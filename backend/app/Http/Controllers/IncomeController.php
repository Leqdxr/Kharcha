<?php

namespace App\Http\Controllers;

use App\Models\Income;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

class IncomeController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $incomes = $request->user()->incomes()
            ->orderByDesc('date')
            ->orderByDesc('id')
            ->get();

        return response()->json($incomes);
    }

    public function store(Request $request): JsonResponse
    {
        $income = $request->user()->incomes()->create($this->validateIncome($request));

        return response()->json($income->refresh(), 201);
    }

    public function update(Request $request, Income $income): JsonResponse
    {
        $this->authorizeOwner($request, $income);

        $income->update($this->validateIncome($request));

        return response()->json($income);
    }

    public function destroy(Request $request, Income $income): Response
    {
        $this->authorizeOwner($request, $income);

        $income->delete();

        return response()->noContent();
    }

    private function validateIncome(Request $request): array
    {
        return $request->validate([
            'title' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0|max:9999999999',
            'type' => ['required', Rule::in(array_keys(config('tax.tds_types')))],
            'tds_amount' => 'required|numeric|min:0|lte:amount',
            'date' => 'required|date',
            'note' => 'nullable|string|max:255',
        ]);
    }
}
