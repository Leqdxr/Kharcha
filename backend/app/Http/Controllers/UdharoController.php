<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Udharo;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class UdharoController extends Controller
{
    /**
     * Unsettled entries only; settled ones are hidden.
     */
    public function index(Request $request): JsonResponse
    {
        $udharos = $request->user()->udharos()
            ->whereNull('settled_at')
            ->orderByDesc('date')
            ->orderByDesc('id')
            ->get();

        return response()->json($udharos);
    }

    public function store(Request $request): JsonResponse
    {
        $udharo = $request->user()->udharos()->create($this->validateUdharo($request));

        return response()->json($udharo->refresh(), 201);
    }

    public function update(Request $request, Udharo $udharo): JsonResponse
    {
        $this->authorizeOwner($request, $udharo);

        $udharo->update($this->validateUdharo($request));

        return response()->json($udharo);
    }

    public function destroy(Request $request, Udharo $udharo): Response
    {
        $this->authorizeOwner($request, $udharo);

        $udharo->delete();

        return response()->noContent();
    }

    public function settle(Request $request, Udharo $udharo): JsonResponse
    {
        $this->authorizeOwner($request, $udharo);

        $udharo->update(['settled_at' => $udharo->settled_at ?? now()]);

        return response()->json($udharo);
    }

    public function unsettle(Request $request, Udharo $udharo): JsonResponse
    {
        $this->authorizeOwner($request, $udharo);

        $udharo->update(['settled_at' => null]);

        return response()->json($udharo);
    }

    /**
     * Split a bill you paid equally between you and your friends. Each friend's
     * share is rounded down to whole rupees and you take the remainder. Every
     * friend gets a "lent" entry and your share is saved as an expense.
     */
    public function split(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'total' => 'required|numeric|min:1|max:9999999999',
            'friends' => 'required|array|min:1|max:20',
            'friends.*' => 'required|string|max:100|distinct',
            'category' => ['sometimes', Rule::in(Expense::CATEGORIES)],
            'payment_method' => ['nullable', Rule::in(User::PAYMENT_METHODS)],
            'date' => 'sometimes|date',
        ]);

        $people = count($data['friends']) + 1;
        $share = floor($data['total'] / $people);
        if ($share < 1) {
            throw ValidationException::withMessages(['total' => 'The total is too small to split between '.$people.' people.']);
        }
        $yourShare = round($data['total'] - $share * ($people - 1), 2);
        $date = $data['date'] ?? Carbon::today()->toDateString();
        $user = $request->user();

        [$udharos, $expense] = DB::transaction(function () use ($user, $data, $share, $yourShare, $date) {
            $udharos = collect($data['friends'])->map(fn (string $friend) => $user->udharos()->create([
                'person' => $friend,
                'amount' => $share,
                'direction' => 'lent',
                'note' => $data['title'],
                'date' => $date,
            ]));

            $expense = $user->expenses()->create([
                'title' => $data['title'],
                'amount' => $yourShare,
                'category' => $data['category'] ?? 'Food',
                'payment_method' => $data['payment_method'] ?? null,
                'date' => $date,
                'note' => Str::limit('Split with '.implode(', ', $data['friends']), 250),
            ]);

            return [$udharos, $expense];
        });

        return response()->json(['udharos' => $udharos, 'expense' => $expense], 201);
    }

    private function validateUdharo(Request $request): array
    {
        return $request->validate([
            'person' => 'required|string|max:100',
            'amount' => 'required|numeric|min:1|max:9999999999',
            'direction' => ['required', Rule::in(Udharo::DIRECTIONS)],
            'note' => 'nullable|string|max:255',
            'date' => 'required|date',
        ]);
    }
}
