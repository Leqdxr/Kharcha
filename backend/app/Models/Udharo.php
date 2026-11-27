<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Money lent to a friend (they owe me) or borrowed from one (I owe them).
 */
#[Fillable(['person', 'amount', 'direction', 'note', 'date', 'settled_at'])]
class Udharo extends Model
{
    public const DIRECTIONS = ['lent', 'borrowed'];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'float',
            'date' => 'date:Y-m-d',
            'settled_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
