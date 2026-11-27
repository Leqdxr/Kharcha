<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // On: income lists show the Nepali fiscal year (Shrawan to Asar).
            // Off: the calendar year. The tax estimate always uses the fiscal year.
            $table->boolean('fiscal_year_view')->default(true)->after('ssf_contributor');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('fiscal_year_view');
        });
    }
};
