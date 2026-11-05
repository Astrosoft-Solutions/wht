<?php

namespace Database\Factories;

use App\Models\Plan;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Plan>
 */
class PlanFactory extends Factory
{
    public function definition(): array
    {
        [$coachType, $tier] = $this->firstFreeSlot();

        return [
            'coach_type' => $coachType,
            'tier' => $tier,
            'name' => ucfirst($coachType).' '.ucfirst($tier),
            'price_paise' => 99900,
            'currency' => 'INR',
            'duration_days' => 30,
            'max_customers' => 10,
            'features' => ['Habit tracking'],
            'is_active' => true,
        ];
    }

    public function tier(string $coachType, string $tier, ?int $maxCustomers = 10): static
    {
        return $this->state(fn () => [
            'coach_type' => $coachType,
            'tier' => $tier,
            'name' => ucfirst($coachType).' '.ucfirst($tier),
            'max_customers' => $maxCustomers,
        ]);
    }

    /**
     * Plans are unique per coach type and tier, so default to a combination not used yet.
     *
     * @return array{0: string, 1: string}
     */
    private function firstFreeSlot(): array
    {
        $taken = Plan::query()->get(['coach_type', 'tier'])
            ->map(fn (Plan $plan) => $plan->coach_type.'.'.$plan->tier)
            ->all();

        foreach (Plan::COACH_TYPES as $coachType) {
            foreach (Plan::TIERS as $tier) {
                if (! in_array("{$coachType}.{$tier}", $taken, true)) {
                    return [$coachType, $tier];
                }
            }
        }

        return ['coach', 'gold'];
    }
}
