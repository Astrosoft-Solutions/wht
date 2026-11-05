<?php

namespace Database\Seeders;

use App\Models\Plan;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([PlanSeeder::class, MasterHabitSeeder::class, ContentSeeder::class]);

        $admin = User::updateOrCreate(
            ['email' => env('SUPERADMIN_EMAIL', 'admin@wellnesshabittracker.com')],
            ['name' => 'Super Admin', 'password' => env('SUPERADMIN_PASSWORD', 'password')],
        );
        $admin->forceFill(['role' => User::ROLE_SUPERADMIN, 'coach_type' => null])->save();

        $coach = User::updateOrCreate(
            ['email' => 'vignesh@example.com'],
            ['name' => 'Vignesh', 'mobile' => '9876543210', 'password' => 'password', 'coach_type' => 'coach'],
        );

        if (! $coach->activeSubscription()) {
            app(SubscriptionService::class)->assignManually(
                $coach,
                Plan::where(['coach_type' => 'coach', 'tier' => 'gold'])->firstOrFail(),
                notes: 'Demo account',
            );
        }

        $this->callWith(HabitSeeder::class, ['user' => $coach]);
        $this->callWith(CustomerSeeder::class, ['user' => $coach]);
    }
}
