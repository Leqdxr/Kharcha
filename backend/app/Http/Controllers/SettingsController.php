<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SettingsController extends Controller
{
    /**
     * Update any of the logged-in user's settings. Fields left out stay as they are.
     */
    public function __invoke(Request $request): JsonResponse
    {
        $data = $request->validate([
            'calendar' => ['sometimes', 'required', Rule::in(['bs', 'ad'])],
            'ssf_contributor' => 'sometimes|required|boolean',
            'fiscal_year_view' => 'sometimes|required|boolean',
            'payment_methods' => 'sometimes|present|array',
            'payment_methods.*' => ['distinct', Rule::in(User::PAYMENT_METHODS)],
        ]);

        $user = $request->user();
        $user->update($data);

        return response()->json($user);
    }
}
