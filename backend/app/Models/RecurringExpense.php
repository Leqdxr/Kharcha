<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * A bill that repeats every month on the same day.
 */
#[Fillable(['title', 'amount', 'category', 'payment_method', 'day_of_month', 'next_date'])]
class RecurringExpense extends Model
{
    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'float',
            'day_of_month' => 'integer',
            'next_date' => 'date:Y-m-d',
        ];
    }

    /**
     * The rule's day in the month after $date, moved back to the last day
     * when the month is shorter (31 becomes 28 or 30).
     */
    public function dateInMonthAfter(Carbon $date): Carbon
    {
        $month = $date->copy()->startOfMonth()->addMonth();

        return $month->day(min($this->day_of_month, $month->daysInMonth));
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function expenses(): HasMany
    {
        return $this->hasMany(Expense::class);
    }
}
