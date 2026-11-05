<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('master_habits', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('icon', 50)->default('check');
            $table->string('color', 9)->default('#2E7D32');
            $table->time('start_time');
            $table->time('end_time')->nullable();
            $table->json('days_of_week')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('gallery_items', function (Blueprint $table) {
            $table->id();
            $table->enum('type', ['image', 'video']);
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('path')->nullable();
            $table->string('video_url')->nullable();
            $table->string('thumbnail_path')->nullable();
            $table->boolean('is_published')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['is_published', 'type']);
        });

        Schema::create('announcements', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('body');
            $table->enum('audience', ['all', 'consultant', 'coach', 'guide'])->default('all');
            $table->timestamp('published_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('announcement_reads', function (Blueprint $table) {
            $table->id();
            $table->foreignId('announcement_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('read_at');

            $table->unique(['announcement_id', 'user_id']);
        });

        Schema::create('app_settings', function (Blueprint $table) {
            $table->string('key', 100)->primary();
            $table->text('value')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_settings');
        Schema::dropIfExists('announcement_reads');
        Schema::dropIfExists('announcements');
        Schema::dropIfExists('gallery_items');
        Schema::dropIfExists('master_habits');
    }
};
