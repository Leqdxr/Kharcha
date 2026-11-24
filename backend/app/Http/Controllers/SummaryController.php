<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class SummaryController extends Controller
{
    /**
     * Totals for one month (default: the current month) of the logged-in user.
     */
    public function __invoke(Request $request): JsonResponse
    {
        $request->validate(['month' => 'nullable|date_format:Y-m']);

        $user = $request->user();
        $month = $request->query('month')
            ? Carbon::parse($request->query('month').'-01')
            : Carbon::today()->startOfMonth();
        $previous = $month->copy()->subMonthNoOverflow();

        $expenses = $user->expenses()->inMonth($month);

        $byCategory = (clone $expenses)
            ->selectRaw('category, SUM(amount) as total')
            ->groupBy('category')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($row) => ['category' => $row->category, 'total' => (float) $row->total]);

        return response()->json([
            'month' => $month->format('Y-m'),
            'total' => (float) (clone $expenses)->sum('amount'),
            'count' => (clone $expenses)->count(),
            'previous_month' => $previous->format('Y-m'),
            'previous_total' => (float) $user->expenses()->inMonth($previous)->sum('amount'),
            'budget' => $user->monthly_budget,
            'by_category' => $byCategory,
        ]);
    }
}
