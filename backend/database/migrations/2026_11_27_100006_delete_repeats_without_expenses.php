<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Before deleting an expense also stopped its monthly repeat, deleting
     * every expense of a repeat left the repeat behind, and it kept showing
     * in "Upcoming bills". Remove those leftovers.
     */
    public function up(): void
    {
        DB::table('recurring_expenses')
            ->whereNotExists(fn ($query) => $query->select(DB::raw(1))
                ->from('expenses')
                ->whereColumn('expenses.recurring_expense_id', 'recurring_expenses.id'))
            ->delete();
    }

    /**
     * Deleted rows can't come back.
     */
    public function down(): void
    {
        //
    }
};
