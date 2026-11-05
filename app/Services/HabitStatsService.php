<?php

namespace App\Services;

use App\Models\Habit;
use App\Models\HabitLog;
use App\Models\User;
use Carbon\CarbonImmutable;
use Carbon\CarbonPeriod;
use Illuminate\Support\Collection;

class HabitStatsService
{
    /**
     * How far back the streak calculation looks.
     */
    private const STREAK_LOOKBACK_DAYS = 365;

    /**
     * @return Collection<int, Habit>
     */
    public function activeHabits(User $user): Collection
    {
        return $user->habits()->active()->ordered()->get();
    }

    /**
     * A habit counts for a date when it is active, scheduled on that weekday and already existed that day.
     *
     * @param  Collection<int, Habit>  $habits
     * @return Collection<int, Habit>
     */
    public function habitsScheduledOn(Collection $habits, CarbonImmutable $date): Collection
    {
        return $habits
            ->filter(fn (Habit $habit) => $habit->isScheduledOn($date)
                && $habit->created_at->toDateString() <= $date->toDateString())
            ->values();
    }

    /**
     * Habits scheduled on the date, each with an `is_completed` flag set.
     *
     * @return Collection<int, Habit>
     */
    public function scheduleFor(User $user, CarbonImmutable $date): Collection
    {
        $habits = $this->habitsScheduledOn($this->activeHabits($user), $date);

        $completedIds = $this->completedLogs($user, $date, $date)
            ->pluck('habit_id')
            ->flip();

        return $habits->each(fn (Habit $habit) => $habit->setAttribute('is_completed', $completedIds->has($habit->id)));
    }

    /**
     * All active habits with completion progress across the range and today's status.
     *
     * @return Collection<int, Habit>
     */
    public function progressFor(User $user, CarbonImmutable $from, CarbonImmutable $to, CarbonImmutable $today): Collection
    {
        $habits = $this->activeHabits($user);
        $logs = $this->completedLogs($user, $from, $to)->groupBy('habit_id');
        $todayLogs = $this->completedLogs($user, $today, $today)->pluck('habit_id')->flip();
        $lastCountedDay = $to->min($today);

        return $habits->each(function (Habit $habit) use ($logs, $todayLogs, $from, $lastCountedDay, $today) {
            $scheduled = 0;
            if ($from->lte($lastCountedDay)) {
                foreach (CarbonPeriod::create($from, $lastCountedDay) as $day) {
                    $day = CarbonImmutable::instance($day);
                    if ($habit->isScheduledOn($day) && $habit->created_at->toDateString() <= $day->toDateString()) {
                        $scheduled++;
                    }
                }
            }

            $habit->setAttribute('is_completed', $todayLogs->has($habit->id));
            $habit->setAttribute('is_scheduled_today', $habit->isScheduledOn($today));
            $habit->setAttribute('completed_count', $logs->get($habit->id)?->count() ?? 0);
            $habit->setAttribute('scheduled_count', $scheduled);
        });
    }

    /**
     * Per-day totals between two dates (inclusive).
     *
     * @return array<string, array{date: string, total: int, completed: int, percent: int}>
     */
    public function dailyBreakdown(User $user, CarbonImmutable $from, CarbonImmutable $to): array
    {
        $habits = $this->activeHabits($user);
        $logs = $this->completedLogs($user, $from, $to)
            ->groupBy(fn (HabitLog $log) => $log->log_date->toDateString());

        $result = [];
        foreach (CarbonPeriod::create($from, $to) as $day) {
            $day = CarbonImmutable::instance($day);
            $key = $day->toDateString();
            $scheduledIds = $this->habitsScheduledOn($habits, $day)->pluck('id');
            $total = $scheduledIds->count();
            $completed = ($logs->get($key) ?? collect())
                ->whereIn('habit_id', $scheduledIds)
                ->count();

            $result[$key] = [
                'date' => $key,
                'total' => $total,
                'completed' => $completed,
                'percent' => $total > 0 ? (int) round($completed / $total * 100) : 0,
            ];
        }

        return $result;
    }

    /**
     * @return array{date: string, total: int, completed: int, percent: int}
     */
    public function dayStats(User $user, CarbonImmutable $date): array
    {
        return $this->dailyBreakdown($user, $date, $date)[$date->toDateString()];
    }

    /**
     * Consecutive fully-completed days ending today. An unfinished today does not break the streak.
     */
    public function streak(User $user, CarbonImmutable $today): int
    {
        $from = $today->subDays(self::STREAK_LOOKBACK_DAYS);
        $days = array_reverse($this->dailyBreakdown($user, $from, $today), true);

        $streak = 0;
        foreach ($days as $date => $day) {
            $isComplete = $day['total'] > 0 && $day['completed'] >= $day['total'];

            if ($isComplete) {
                $streak++;
            } elseif ($date === $today->toDateString() || $day['total'] === 0) {
                continue;
            } else {
                break;
            }
        }

        return $streak;
    }

    /**
     * @return array{month: string, completion_percent: int, total_habits: int, streak: int, completed: int, missed: int, trend: list<array{date: string, total: int, completed: int, percent: int}>}
     */
    public function monthlyReport(User $user, CarbonImmutable $month, CarbonImmutable $today): array
    {
        $from = $month->startOfMonth();
        $to = $month->endOfMonth()->startOfDay()->min($today);

        $days = $from->lte($to) ? $this->dailyBreakdown($user, $from, $to) : [];

        $total = 0;
        $completed = 0;
        $missed = 0;
        foreach ($days as $date => $day) {
            $total += $day['total'];
            $completed += $day['completed'];
            if ($date < $today->toDateString()) {
                $missed += $day['total'] - $day['completed'];
            }
        }

        return [
            'month' => $from->format('Y-m'),
            'completion_percent' => $total > 0 ? (int) round($completed / $total * 100) : 0,
            'total_habits' => $user->habits()->active()->count(),
            'streak' => $this->streak($user, $today),
            'completed' => $completed,
            'missed' => $missed,
            'trend' => array_values($days),
        ];
    }

    /**
     * @return Collection<int, HabitLog>
     */
    private function completedLogs(User $user, CarbonImmutable $from, CarbonImmutable $to): Collection
    {
        return $user->habitLogs()
            ->where('status', HabitLog::STATUS_COMPLETED)
            ->whereBetween('log_date', [$from->toDateString(), $to->toDateString()])
            ->get(['id', 'habit_id', 'log_date']);
    }
}
