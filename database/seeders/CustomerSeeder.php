<?php

namespace Database\Seeders;

use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;

class CustomerSeeder extends Seeder
{
    public function run(User $user): void
    {
        $user->customers()->each(fn ($customer) => $customer->delete());

        $monthStart = CarbonImmutable::today()->startOfMonth();

        $ramesh = $user->customers()->create([
            'customer_code' => 'CUST001',
            'name' => 'Ramesh Kumar',
            'phone' => '9840012345',
            'height_cm' => 174,
            'status' => 'active',
            'health_condition_before' => 'Overweight, low energy, breathing issue.',
            'remarks' => 'After 3 months - 10 kg weight loss, energy improved, no breathing issue.',
        ]);

        $programme = $ramesh->programmes()->create([
            'name' => 'Programme 1',
            'goal' => 'Weight Loss',
            'total_weeks' => 12,
            'weeks_completed' => 10,
            'start_date' => $monthStart->subWeeks(10)->toDateString(),
        ]);

        $rows = [
            [80.0, 30.5, 26.4, 28.0, 12.0, 46, 98, 86],
            [79.8, 30.2, 26.3, 28.2, 11.8, 33, 98, 85],
            [79.5, 30.0, 26.2, 28.4, 11.6, 33, 98, 85],
        ];
        foreach ($rows as $i => [$weight, $fat, $bmi, $muscle, $visceral, $bodyAge, $chest, $waist]) {
            $ramesh->measurements()->create([
                'programme_id' => $programme->id,
                'recorded_on' => $monthStart->addDays($i)->toDateString(),
                'weight' => $weight,
                'fat_percent' => $fat,
                'bmi' => $bmi,
                'muscle' => $muscle,
                'visceral_fat' => $visceral,
                'body_age' => $bodyAge,
                'chest' => $chest,
                'waist' => $waist,
                'total_points' => 10,
            ]);
        }

        $others = [
            ['CUST002', 'Priya S', '9840022222', 'active', 160, 64],
            ['CUST003', 'Arun Prakash', '9840033333', 'inactive', 178, 88],
            ['CUST004', 'Divya R', '9840044444', 'active', 158, 61],
            ['CUST005', 'Karthik M', '9840055555', 'active', 172, 79],
        ];
        foreach ($others as [$code, $name, $phone, $status, $height, $weight]) {
            $customer = $user->customers()->create([
                'customer_code' => $code,
                'name' => $name,
                'phone' => $phone,
                'height_cm' => $height,
                'status' => $status,
            ]);
            $customer->measurements()->create([
                'recorded_on' => $monthStart->toDateString(),
                'weight' => $weight,
            ]);
        }

        $lakshmi = $user->customers()->create([
            'customer_code' => 'CUST006',
            'name' => 'Lakshmi Priya',
            'height_cm' => 165,
            'status' => 'active',
        ]);
        $lakshmi->measurements()->create([
            'recorded_on' => $monthStart->toDateString(),
            'weight' => 72,
            'fat_percent' => 32,
            'bmi' => 26.4,
            'muscle' => 28,
            'body_age' => 34,
            'chest' => 98,
            'waist' => 86,
        ]);
    }
}
