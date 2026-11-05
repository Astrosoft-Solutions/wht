<?php

namespace Tests\Feature;

use App\Models\Habit;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HabitTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo(CarbonImmutable::parse('2026-11-04 09:00:00'));
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    }

    private function makeHabits(int $count, string $createdAt = '2026-10-01 00:00:00'): void
    {
        Habit::factory()->count($count)->for($this->user)->create(['created_at' => $createdAt]);
    }

    public function test_user_can_create_update_and_delete_habit(): void
    {
        $id = $this->postJson('/api/v1/habits', [
            'name' => 'Wake Up Time',
            'icon' => 'sunrise',
            'start_time' => '04:00',
            'days_of_week' => [1, 2, 3, 4, 5],
        ])->assertCreated()->assertJsonPath('data.start_time', '04:00')->json('data.id');

        $this->putJson("/api/v1/habits/{$id}", ['name' => 'Early Wake Up'])
            ->assertOk()->assertJsonPath('data.name', 'Early Wake Up');

        $this->deleteJson("/api/v1/habits/{$id}")->assertNoContent();
    }

    public function test_user_cannot_touch_another_users_habit(): void
    {
        $other = Habit::factory()->create();

        $this->putJson("/api/v1/habits/{$other->id}", ['name' => 'x'])->assertForbidden();
        $this->postJson("/api/v1/habits/{$other->id}/toggle")->assertForbidden();
    }

    public function test_toggle_marks_and_unmarks_completion(): void
    {
        $this->makeHabits(2);
        $habit = $this->user->habits()->first();

        $this->postJson("/api/v1/habits/{$habit->id}/toggle", ['date' => '2026-11-04'])
            ->assertOk()
            ->assertJsonPath('is_completed', true)
            ->assertJsonPath('stats.completed', 1)
            ->assertJsonPath('stats.total', 2)
            ->assertJsonPath('stats.percent', 50);

        $this->postJson("/api/v1/habits/{$habit->id}/toggle", ['date' => '2026-11-04'])
            ->assertOk()
            ->assertJsonPath('is_completed', false)
            ->assertJsonPath('stats.completed', 0);
    }

    public function test_complete_all_marks_every_scheduled_habit(): void
    {
        $this->makeHabits(3);

        $this->postJson('/api/v1/habits/complete-all', ['date' => '2026-11-04'])
            ->assertOk()
            ->assertJsonPath('stats.completed', 3)
            ->assertJsonPath('stats.percent', 100);
    }

    public function test_schedule_only_includes_habits_for_that_weekday(): void
    {
        // 2026-11-04 is a Wednesday (ISO 3).
        Habit::factory()->for($this->user)->create(['days_of_week' => [3], 'created_at' => '2026-10-01']);
        Habit::factory()->for($this->user)->create(['days_of_week' => [6, 7], 'created_at' => '2026-10-01']);

        $this->getJson('/api/v1/habits/schedule?range=today&date=2026-11-04')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_week_schedule_returns_progress_counts(): void
    {
        $this->makeHabits(1);
        $habit = $this->user->habits()->first();
        $habit->logs()->create(['user_id' => $this->user->id, 'log_date' => '2026-11-02', 'status' => 'completed']);

        $this->getJson('/api/v1/habits/schedule?range=week&date=2026-11-04')
            ->assertOk()
            ->assertJsonPath('from', '2026-11-02')
            ->assertJsonPath('data.0.completed_count', 1)
            ->assertJsonPath('data.0.scheduled_count', 3);
    }

    public function test_dashboard_reports_stats_and_streak(): void
    {
        $this->makeHabits(2);
        $habits = $this->user->habits()->get();

        foreach (['2026-11-01', '2026-11-02', '2026-11-03'] as $date) {
            foreach ($habits as $habit) {
                $habit->logs()->create(['user_id' => $this->user->id, 'log_date' => $date, 'status' => 'completed']);
            }
        }
        $habits[0]->logs()->create(['user_id' => $this->user->id, 'log_date' => '2026-11-04', 'status' => 'completed']);

        $this->getJson('/api/v1/dashboard?date=2026-11-04')
            ->assertOk()
            ->assertJsonPath('habits_total', 2)
            ->assertJsonPath('habits_completed', 1)
            ->assertJsonPath('completion_percent', 50)
            ->assertJsonPath('streak', 3)
            ->assertJsonCount(2, 'schedule');
    }
}
