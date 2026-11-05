<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ResolvesDate;
use App\Http\Controllers\Controller;
use App\Services\HabitStatsService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    use ResolvesDate;

    public function __invoke(Request $request, HabitStatsService $stats): JsonResponse
    {
        $request->validate(['month' => ['nullable', 'date_format:Y-m']]);
        $today = $this->resolveDate($request);

        $month = $request->filled('month')
            ? CarbonImmutable::createFromFormat('!Y-m', $request->input('month'))
            : $today->startOfMonth();

        return response()->json([
            'data' => $stats->monthlyReport($request->user(), $month, $today),
        ]);
    }
}
