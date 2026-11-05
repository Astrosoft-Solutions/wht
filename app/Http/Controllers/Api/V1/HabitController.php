<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ResolvesDate;
use App\Http\Controllers\Controller;
use App\Http\Requests\HabitRequest;
use App\Http\Resources\HabitResource;
use App\Models\Habit;
use App\Models\HabitLog;
use App\Services\HabitStatsService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

class HabitController extends Controller
{
    use ResolvesDate;

    public function __construct(private readonly HabitStatsService $stats) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $habits = $request->user()->habits()->ordered()->get();

        return HabitResource::collection($habits);
    }

    public function store(HabitRequest $request): JsonResponse
    {
        $habit = $request->user()->habits()->create($request->validated());

        return (new HabitResource($habit->refresh()))->response()->setStatusCode(201);
    }

    public function show(Habit $habit): HabitResource
    {
        Gate::authorize('view', $habit);

        return new HabitResource($habit);
    }

    public function update(HabitRequest $request, Habit $habit): HabitResource
    {
        Gate::authorize('update', $habit);

        $habit->update($request->validated());

        return new HabitResource($habit->refresh());
    }

    public function destroy(Habit $habit): JsonResponse
    {
        Gate::authorize('delete', $habit);

        $habit->delete();

        return response()->json(null, 204);
    }

    /**
     * Today: habits scheduled for the date. Week/month: every active habit with its progress over the range.
     */
    public function schedule(Request $request): JsonResponse
    {
        $request->validate(['range' => ['nullable', 'in:today,week,month']]);
        $date = $this->resolveDate($request);
        $range = $request->input('range', 'today');
        $user = $request->user();

        if ($range === 'today') {
            $habits = $this->stats->scheduleFor($user, $date);
            $from = $to = $date;
        } else {
            [$from, $to] = $range === 'week'
                ? [$date->startOfWeek(CarbonImmutable::MONDAY), $date->endOfWeek(CarbonImmutable::SUNDAY)->startOfDay()]
                : [$date->startOfMonth(), $date->endOfMonth()->startOfDay()];
            $habits = $this->stats->progressFor($user, $from, $to, $date);
        }

        return response()->json([
            'range' => $range,
            'date' => $date->toDateString(),
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
            'data' => HabitResource::collection($habits),
        ]);
    }

    public function toggle(Request $request, Habit $habit): JsonResponse
    {
        Gate::authorize('update', $habit);
        $date = $this->ensureNotFuture($this->resolveDate($request));

        $log = $habit->logs()->whereDate('log_date', $date)->first();

        if ($log && $log->status === HabitLog::STATUS_COMPLETED) {
            $log->delete();
            $completed = false;
        } else {
            $habit->logs()->updateOrCreate(
                ['log_date' => $date->toDateString()],
                ['user_id' => $habit->user_id, 'status' => HabitLog::STATUS_COMPLETED, 'completed_at' => now()],
            );
            $completed = true;
        }

        return response()->json([
            'habit_id' => $habit->id,
            'date' => $date->toDateString(),
            'is_completed' => $completed,
            'stats' => $this->stats->dayStats($request->user(), $date),
        ]);
    }

    public function completeAll(Request $request): JsonResponse
    {
        $date = $this->ensureNotFuture($this->resolveDate($request));
        $user = $request->user();

        foreach ($this->stats->scheduleFor($user, $date) as $habit) {
            if (! $habit->is_completed) {
                $habit->logs()->updateOrCreate(
                    ['log_date' => $date->toDateString()],
                    ['user_id' => $user->id, 'status' => HabitLog::STATUS_COMPLETED, 'completed_at' => now()],
                );
            }
        }

        return response()->json([
            'date' => $date->toDateString(),
            'stats' => $this->stats->dayStats($user, $date),
            'data' => HabitResource::collection($this->stats->scheduleFor($user, $date)),
        ]);
    }

    private function ensureNotFuture(CarbonImmutable $date): CarbonImmutable
    {
        // One day of slack because the device's local date can be ahead of the server's.
        if ($date->gt(CarbonImmutable::today()->addDay())) {
            throw ValidationException::withMessages(['date' => ['Habits cannot be completed for future dates.']]);
        }

        return $date;
    }
}
