<?php

namespace Tests\Feature;

use App\Models\Habit;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_monthly_report_aggregates_completion(): void
    {
        $this->travelTo(CarbonImmutable::parse('2026-11-03 10:00:00'));
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $habits = Habit::factory()->count(2)->for($user)->create(['created_at' => '2026-10-01']);

        // Nov 1: 2/2, Nov 2: 1/2, Nov 3 (today): 0/2 so far.
        foreach ($habits as $habit) {
            $habit->logs()->create(['user_id' => $user->id, 'log_date' => '2026-11-01', 'status' => 'completed']);
        }
        $habits[0]->logs()->create(['user_id' => $user->id, 'log_date' => '2026-11-02', 'status' => 'completed']);

        $this->getJson('/api/v1/reports?month=2026-11&date=2026-11-03')
            ->assertOk()
            ->assertJsonPath('data.month', '2026-11')
            ->assertJsonPath('data.total_habits', 2)
            ->assertJsonPath('data.completed', 3)
            ->assertJsonPath('data.missed', 1)
            ->assertJsonPath('data.completion_percent', 50)
            ->assertJsonCount(3, 'data.trend')
            ->assertJsonPath('data.trend.0.percent', 100)
            ->assertJsonPath('data.trend.1.percent', 50);
    }
}
