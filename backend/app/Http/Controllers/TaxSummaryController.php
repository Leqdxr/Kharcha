<?php

namespace App\Http\Controllers;

use App\Services\TaxEstimator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaxSummaryController extends Controller
{
    /**
     * Income, TDS and the tax estimate for the current fiscal year.
     */
    public function __invoke(Request $request, TaxEstimator $estimator): JsonResponse
    {
        return response()->json($estimator->estimate($request->user()));
    }
}
