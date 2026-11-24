<?php

namespace Database\Seeders;

use App\Models\Announcement;
use App\Models\AppSetting;
use Illuminate\Database\Seeder;

class ContentSeeder extends Seeder
{
    public function run(): void
    {
        foreach (AppSetting::REMINDER_DEFAULTS as $key => $value) {
            AppSetting::firstOrCreate(['key' => $key], ['value' => is_bool($value) ? ($value ? '1' : '0') : (string) $value]);
        }

        Announcement::firstOrCreate(
            ['title' => 'Welcome to WellnessHabitTrack'],
            [
                'body' => 'Track your daily habits, manage your customers and follow their progress, all in one app.',
                'audience' => 'all',
                'published_at' => now(),
            ],
        );
    }
}
