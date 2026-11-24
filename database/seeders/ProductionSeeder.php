<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use RuntimeException;

/**
 * Seeds a fresh production database: plans, master habits, reminder defaults and the
 * superadmin login. Unlike DatabaseSeeder it creates no demo coach or customers.
 */
class ProductionSeeder extends Seeder
{
    public function run(): void
    {
        $email = (string) config('services.superadmin.email');
        $password = (string) config('services.superadmin.password');
        if ($email === '' || $password === '') {
            throw new RuntimeException('Set SUPERADMIN_EMAIL and SUPERADMIN_PASSWORD in .env before the first deploy.');
        }

        $this->call([PlanSeeder::class, MasterHabitSeeder::class, ContentSeeder::class]);

        $admin = User::firstOrCreate(['email' => $email], ['name' => 'Super Admin', 'password' => $password]);
        $admin->forceFill(['role' => User::ROLE_SUPERADMIN, 'coach_type' => null])->save();
    }
}
