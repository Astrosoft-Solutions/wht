<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Habit>
 */
class HabitFactory extends Factory
{
    public function definition(): array
    {
        $hour = fake()->numberBetween(4, 21);

        return [
            'user_id' => User::factory(),
            'name' => fake()->randomElement(['Wake Up Time', 'Prayer Time', 'Fitness Time', 'Water Time', 'Bed Time']),
            'icon' => 'check',
            'color' => '#2E7D32',
            'start_time' => sprintf('%02d:00:00', $hour),
            'end_time' => sprintf('%02d:30:00', $hour),
            'days_of_week' => null,
            'sort_order' => 0,
            'is_active' => true,
        ];
    }
}
