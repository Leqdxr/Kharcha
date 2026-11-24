<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    /**
     * Set or clear (null) the logged-in user's monthly budget.
     */
    public function __invoke(Request $request): JsonResponse
    {
        $data = $request->validate([
            'monthly_budget' => 'present|nullable|integer|min:0|max:100000000',
        ]);

        $user = $request->user();
        $user->update($data);

        return response()->json($user);
    }
}
