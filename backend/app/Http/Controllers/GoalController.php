<?php

namespace App\Http\Controllers;

use App\Models\Goal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class GoalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json($request->user()->goals()->orderBy('id')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $goal = $request->user()->goals()->create($this->validateGoal($request));

        return response()->json($goal->refresh(), 201);
    }

    public function update(Request $request, Goal $goal): JsonResponse
    {
        $this->authorizeOwner($request, $goal);

        $goal->update($this->validateGoal($request));

        return response()->json($goal);
    }

    public function destroy(Request $request, Goal $goal): Response
    {
        $this->authorizeOwner($request, $goal);

        $goal->delete();

        return response()->noContent();
    }

    public function deposit(Request $request, Goal $goal): JsonResponse
    {
        $this->authorizeOwner($request, $goal);

        $data = $request->validate(['amount' => 'required|numeric|min:1|max:9999999999']);

        $goal->increment('saved', $data['amount']);

        return response()->json($goal->refresh());
    }

    private function validateGoal(Request $request): array
    {
        return $request->validate([
            'name' => 'required|string|max:100',
            'target' => 'required|numeric|min:1|max:9999999999',
            'saved' => 'sometimes|numeric|min:0|max:9999999999',
            'target_date' => 'nullable|date',
            'note' => 'nullable|string|max:255',
        ]);
    }
}
