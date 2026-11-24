<?php

namespace Database\Seeders;

use App\Models\Plan;
use Illuminate\Database\Seeder;

class PlanSeeder extends Seeder
{
    /**
     * Monthly price in rupees per coach type and tier.
     */
    private const PRICES = [
        'consultant' => ['gold' => 5999, 'silver' => 2999, 'bronze' => 1499],
        'coach' => ['gold' => 3999, 'silver' => 1999, 'bronze' => 999],
        'guide' => ['gold' => 1999, 'silver' => 999, 'bronze' => 499],
    ];

    private const TIERS = [
        'gold' => [
            'max_customers' => null,
            'features' => ['Unlimited customers', 'Habit tracking & reports', 'Service records & progress charts', 'Before & after photos', 'Priority support'],
        ],
        'silver' => [
            'max_customers' => 30,
            'features' => ['Up to 30 customers', 'Habit tracking & reports', 'Service records & progress charts', 'Before & after photos'],
        ],
        'bronze' => [
            'max_customers' => 10,
            'features' => ['Up to 10 customers', 'Habit tracking & reports', 'Service records'],
        ],
    ];

    public function run(): void
    {
        $order = 0;
        foreach (self::PRICES as $coachType => $prices) {
            foreach ($prices as $tier => $rupees) {
                Plan::updateOrCreate(
                    ['coach_type' => $coachType, 'tier' => $tier],
                    [
                        'name' => ucfirst($coachType).' '.ucfirst($tier),
                        'description' => ucfirst($tier).' plan for '.$coachType.'s, billed every 30 days.',
                        'price_paise' => $rupees * 100,
                        'currency' => 'INR',
                        'duration_days' => 30,
                        'max_customers' => self::TIERS[$tier]['max_customers'],
                        'features' => self::TIERS[$tier]['features'],
                        'is_active' => true,
                        'sort_order' => $order++,
                    ],
                );
            }
        }
    }
}
