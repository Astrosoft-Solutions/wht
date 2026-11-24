<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('role', ['superadmin', 'coach'])->default('coach')->after('avatar_path');
            $table->enum('coach_type', ['consultant', 'coach', 'guide'])->nullable()->after('role');
            $table->enum('status', ['active', 'inactive'])->default('active')->after('coach_type');

            $table->index(['role', 'coach_type', 'status']);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['role', 'coach_type', 'status']);
            $table->dropColumn(['role', 'coach_type', 'status']);
        });
    }
};
