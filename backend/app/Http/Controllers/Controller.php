<?php

namespace App\Http\Controllers;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

abstract class Controller
{
    /**
     * Stop with 403 unless the row belongs to the logged-in user.
     */
    protected function authorizeOwner(Request $request, Model $model): void
    {
        abort_if($model->user_id !== $request->user()->id, 403, 'This does not belong to you.');
    }
}
