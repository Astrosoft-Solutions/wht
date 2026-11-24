<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\SubscriptionResource;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    private const REVENUE_MONTHS = 6;

    public function __invoke(): JsonResponse
    {
        $coaches = User::coaches();
        $byType = (clone $coaches)->selectRaw('coach_type, COUNT(*) AS total')->groupBy('coach_type')->pluck('total', 'coach_type');

        $current = Subscription::current()->with('plan')->get();

        $paid = Subscription::whereIn('source', ['panel', 'app'])
            ->whereIn('status', [Subscription::STATUS_ACTIVE, Subscription::STATUS_EXPIRED])
            ->whereNotNull('razorpay_payment_id')
            ->where('created_at', '>=', now()->startOfMonth()->subMonths(self::REVENUE_MONTHS - 1))
            ->get(['amount_paise', 'created_at']);

        $revenueByMonth = collect(range(self::REVENUE_MONTHS - 1, 0))->map(function (int $monthsAgo) use ($paid) {
            $month = now()->startOfMonth()->subMonths($monthsAgo);

            return [
                'month' => $month->format('Y-m'),
                'label' => $month->format('M Y'),
                'amount' => round($paid->filter(fn ($s) => $s->created_at->format('Y-m') === $month->format('Y-m'))->sum('amount_paise') / 100, 2),
            ];
        })->values();

        $expiring = Subscription::current()
            ->where('ends_at', '<=', now()->addDays(7))
            ->with(['plan', 'user'])
            ->orderBy('ends_at')
            ->limit(10)
            ->get();

        $recent = Subscription::whereIn('status', [Subscription::STATUS_ACTIVE, Subscription::STATUS_EXPIRED])
            ->with(['plan', 'user'])
            ->latest()
            ->limit(10)
            ->get();

        return response()->json([
            'coaches' => [
                'total' => (clone $coaches)->count(),
                'active' => (clone $coaches)->where('status', 'active')->count(),
                'new_this_month' => (clone $coaches)->where('created_at', '>=', now()->startOfMonth())->count(),
                'by_type' => collect(Plan::COACH_TYPES)->mapWithKeys(fn ($t) => [$t => (int) ($byType[$t] ?? 0)]),
            ],
            'subscriptions' => [
                'active' => $current->count(),
                'by_tier' => collect(Plan::TIERS)->mapWithKeys(fn ($t) => [$t => $current->where('plan.tier', $t)->count()]),
                'by_type' => collect(Plan::COACH_TYPES)->mapWithKeys(fn ($t) => [$t => $current->where('plan.coach_type', $t)->count()]),
            ],
            'revenue' => [
                'this_month' => $revenueByMonth->last()['amount'],
                'currency' => 'INR',
                'by_month' => $revenueByMonth,
            ],
            'expiring_soon' => SubscriptionResource::collection($expiring),
            'recent_subscriptions' => SubscriptionResource::collection($recent),
        ]);
    }
}
