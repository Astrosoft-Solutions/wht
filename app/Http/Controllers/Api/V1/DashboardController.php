<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ResolvesDate;
use App\Http\Controllers\Controller;
use App\Http\Resources\HabitResource;
use App\Http\Resources\UserResource;
use App\Services\HabitStatsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    use ResolvesDate;

    public function __invoke(Request $request, HabitStatsService $stats): JsonResponse
    {
        $date = $this->resolveDate($request);
        $user = $request->user();
        $day = $stats->dayStats($user, $date);

        return response()->json([
            'user' => new UserResource($user),
            'date' => $date->toDateString(),
            'habits_total' => $day['total'],
            'habits_completed' => $day['completed'],
            'completion_percent' => $day['percent'],
            'streak' => $stats->streak($user, $date),
            'schedule' => HabitResource::collection($stats->scheduleFor($user, $date)),
        ]);
    }
}
