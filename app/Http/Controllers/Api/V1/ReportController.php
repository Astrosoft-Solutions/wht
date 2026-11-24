<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ResolvesDate;
use App\Http\Controllers\Controller;
use App\Services\HabitStatsService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ReportController extends Controller
{
    use ResolvesDate;

    private const MAX_RANGE_DAYS = 366;

    public function __invoke(Request $request, HabitStatsService $stats): JsonResponse
    {
        $request->validate([
            'month' => ['nullable', 'date_format:Y-m'],
            'from' => ['nullable', 'date_format:Y-m-d', 'required_with:to'],
            'to' => ['nullable', 'date_format:Y-m-d', 'required_with:from', 'after_or_equal:from'],
        ]);

        $today = $this->resolveDate($request);

        if ($request->filled('from') && $request->filled('to')) {
            $from = CarbonImmutable::createFromFormat('Y-m-d', $request->input('from'))->startOfDay();
            $to = CarbonImmutable::createFromFormat('Y-m-d', $request->input('to'))->startOfDay();

            if ($from->diffInDays($to) + 1 > self::MAX_RANGE_DAYS) {
                throw ValidationException::withMessages([
                    'to' => ['The date range may not exceed '.self::MAX_RANGE_DAYS.' days.'],
                ]);
            }

            return response()->json([
                'data' => $stats->rangeReport($request->user(), $from, $to, $today),
            ]);
        }

        $month = $request->filled('month')
            ? CarbonImmutable::createFromFormat('!Y-m', $request->input('month'))
            : $today->startOfMonth();

        return response()->json([
            'data' => $stats->monthlyReport($request->user(), $month, $today),
        ]);
    }
}
