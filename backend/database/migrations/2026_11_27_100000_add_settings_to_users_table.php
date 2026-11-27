<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('calendar', ['bs', 'ad'])->default('bs')->after('monthly_budget');
            $table->boolean('ssf_contributor')->default(false)->after('calendar');
            $table->json('payment_methods')->nullable()->after('ssf_contributor');
        });

        DB::table('users')->update(['payment_methods' => json_encode(['cash', 'esewa', 'khalti', 'bank_card', 'mobile_banking'])]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['calendar', 'ssf_contributor', 'payment_methods']);
        });
    }
};
