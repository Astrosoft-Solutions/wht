<?php

namespace Database\Seeders;

use App\Models\HabitLog;
use App\Models\MasterHabit;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;

/**
 * Gives the demo coach copies of the master habits plus 45 days of completion history.
 */
class HabitSeeder extends Seeder
{
    public function run(User $user): void
    {
        $today = CarbonImmutable::today();
        $createdAt = $today->subDays(45);

        $user->habitLogs()->delete();
        $user->habits()->delete();

        $habits = MasterHabit::active()->ordered()->get()->map(function (MasterHabit $template) use ($user, $createdAt) {
            $habit = $user->habits()->make($template->toHabitAttributes());
            $habit->created_at = $createdAt;
            $habit->save();

            return $habit;
        });

        mt_srand(42);
        $logs = [];
        for ($daysAgo = 45; $daysAgo >= 0; $daysAgo--) {
            $date = $today->subDays($daysAgo);

            // Last three days fully complete for a 3-day streak, the day before is partial, today is in progress.
            $completeCount = match (true) {
                $daysAgo === 0 => 6,
                $daysAgo <= 3 => $habits->count(),
                $daysAgo === 4 => (int) floor($habits->count() * 0.6),
                default => mt_rand((int) floor($habits->count() * 0.4), $habits->count()),
            };

            foreach ($habits->take($completeCount) as $habit) {
                $logs[] = [
                    'habit_id' => $habit->id,
                    'user_id' => $user->id,
                    'log_date' => $date->toDateString(),
                    'status' => HabitLog::STATUS_COMPLETED,
                    'completed_at' => $date->setTimeFromTimeString($habit->start_time),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        foreach (array_chunk($logs, 500) as $chunk) {
            HabitLog::insert($chunk);
        }
    }
}
