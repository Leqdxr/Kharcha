<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\BudgetController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\GoalController;
use App\Http\Controllers\IncomeController;
use App\Http\Controllers\RecurringExpenseController;
use App\Http\Controllers\SettingsController;
use App\Http\Controllers\SummaryController;
use App\Http\Controllers\TaxSummaryController;
use App\Http\Controllers\UdharoController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $request) => $request->user());
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::apiResource('expenses', ExpenseController::class)->except('show');
    Route::apiResource('recurring-expenses', RecurringExpenseController::class)->only(['index', 'store', 'destroy']);
    Route::get('/summary', SummaryController::class);
    Route::put('/budget', BudgetController::class);
    Route::put('/settings', SettingsController::class);
    Route::apiResource('incomes', IncomeController::class)->except('show');
    Route::get('/tax/summary', TaxSummaryController::class);
    Route::post('/udharos/split', [UdharoController::class, 'split']);
    Route::post('/udharos/{udharo}/settle', [UdharoController::class, 'settle']);
    Route::post('/udharos/{udharo}/unsettle', [UdharoController::class, 'unsettle']);
    Route::apiResource('udharos', UdharoController::class)->except('show');
    Route::post('/goals/{goal}/deposit', [GoalController::class, 'deposit']);
    Route::apiResource('goals', GoalController::class)->except('show');
});
