<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('customer_code', 20);
            $table->string('name');
            $table->string('phone', 20)->nullable();
            $table->string('email')->nullable();
            $table->decimal('height_cm', 5, 1)->nullable();
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->text('health_condition_before')->nullable();
            $table->text('remarks')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'customer_code']);
            $table->index(['user_id', 'name']);
        });

        Schema::create('programmes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('goal')->nullable();
            $table->unsignedSmallInteger('total_weeks')->default(12);
            $table->unsignedSmallInteger('weeks_completed')->default(0);
            $table->date('start_date')->nullable();
            $table->timestamps();
        });

        Schema::create('customer_measurements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->foreignId('programme_id')->nullable()->constrained()->nullOnDelete();
            $table->date('recorded_on');
            $table->decimal('weight', 5, 1)->nullable();
            $table->decimal('fat_percent', 4, 1)->nullable();
            $table->decimal('bmi', 4, 1)->nullable();
            $table->decimal('muscle', 5, 1)->nullable();
            $table->decimal('visceral_fat', 4, 1)->nullable();
            $table->unsignedSmallInteger('body_age')->nullable();
            $table->decimal('chest', 5, 1)->nullable();
            $table->decimal('waist', 5, 1)->nullable();
            $table->string('hp', 20)->nullable();
            $table->string('rm_24', 20)->nullable();
            $table->unsignedInteger('total_points')->nullable();
            $table->timestamps();

            $table->index(['customer_id', 'recorded_on']);
        });

        Schema::create('customer_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['before', 'after']);
            $table->string('path');
            $table->date('taken_on')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_photos');
        Schema::dropIfExists('customer_measurements');
        Schema::dropIfExists('programmes');
        Schema::dropIfExists('customers');
    }
};
