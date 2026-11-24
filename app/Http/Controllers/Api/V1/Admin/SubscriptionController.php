<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentResource;
use App\Http\Resources\SubscriptionResource;
use App\Models\Payment;
use App\Models\Plan;
use App\Models\Subscription;
use App\Services\SubscriptionService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class SubscriptionController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'status' => ['nullable', 'in:current,pending,active,expired,cancelled'],
            'coach_type' => ['nullable', Rule::in(Plan::COACH_TYPES)],
            'tier' => ['nullable', Rule::in(Plan::TIERS)],
            'source' => ['nullable', 'in:panel,app,manual'],
            'search' => ['nullable', 'string', 'max:100'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);

        $subscriptions = Subscription::query()
            ->when($request->input('status') === 'current', fn ($q) => $q->current())
            ->when($request->input('status') === 'expired', fn ($q) => $q->where(fn ($q) => $q
                ->where('status', Subscription::STATUS_EXPIRED)
                ->orWhere(fn ($q) => $q->where('status', Subscription::STATUS_ACTIVE)->where('ends_at', '<=', now()))))
            ->when(in_array($request->input('status'), ['pending', 'active', 'cancelled'], true), fn ($q) => $q->where('status', $request->input('status')))
            ->when($request->filled('source'), fn ($q) => $q->where('source', $request->input('source')))
            ->when($request->filled('coach_type') || $request->filled('tier'), fn ($q) => $q->whereHas('plan', fn ($p) => $p
                ->when($request->filled('coach_type'), fn ($p) => $p->where('coach_type', $request->input('coach_type')))
                ->when($request->filled('tier'), fn ($p) => $p->where('tier', $request->input('tier')))))
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%'.$request->input('search').'%';
                $q->whereHas('user', fn ($u) => $u->where('name', 'like', $term)->orWhere('email', 'like', $term));
            })
            ->with(['plan', 'user'])
            ->latest()
            ->paginate($request->integer('per_page', 20));

        return SubscriptionResource::collection($subscriptions);
    }

    public function cancel(Request $request, Subscription $subscription, SubscriptionService $service): SubscriptionResource
    {
        $data = $request->validate(['reason' => ['nullable', 'string', 'max:255']]);

        return new SubscriptionResource($service->cancel($subscription, $data['reason'] ?? 'Cancelled by admin')->load(['plan', 'user']));
    }

    public function payments(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'status' => ['nullable', 'string', 'max:30'],
            'search' => ['nullable', 'string', 'max:100'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);

        $payments = Payment::query()
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->input('status')))
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%'.$request->input('search').'%';
                $q->where(fn ($q) => $q->where('razorpay_order_id', 'like', $term)
                    ->orWhere('razorpay_payment_id', 'like', $term)
                    ->orWhereHas('user', fn ($u) => $u->where('name', 'like', $term)->orWhere('email', 'like', $term)));
            })
            ->with(['user', 'subscription.plan'])
            ->latest()
            ->paginate($request->integer('per_page', 20));

        return PaymentResource::collection($payments);
    }
}
