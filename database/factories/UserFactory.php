<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'remember_token' => Str::random(10),
        ];
    }

    public function superadmin(): static
    {
        return $this->state(fn () => ['role' => 'superadmin', 'coach_type' => null]);
    }

    public function coach(string $type = 'coach'): static
    {
        return $this->state(fn () => ['role' => 'coach', 'coach_type' => $type]);
    }

    /**
     * A coach with a current plan that allows [maxCustomers] customers (null = unlimited).
     */
    public function withPlan(?int $maxCustomers = null, string $tier = 'gold'): static
    {
        return $this->coach()->afterCreating(function (\App\Models\User $user) use ($maxCustomers, $tier) {
            $plan = \App\Models\Plan::firstOrCreate(
                ['coach_type' => $user->coach_type, 'tier' => $tier],
                \App\Models\Plan::factory()->tier($user->coach_type, $tier, $maxCustomers)->raw(),
            );
            \App\Models\Subscription::factory()->for($user)->for($plan)->create();
        });
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }
}
