<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\CoachRequest;
use App\Http\Resources\CoachResource;
use App\Http\Resources\SubscriptionResource;
use App\Models\Plan;
use App\Models\User;
use App\Services\SubscriptionService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class CoachController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'coach_type' => ['nullable', Rule::in(Plan::COACH_TYPES)],
            'status' => ['nullable', 'in:active,inactive'],
            'plan' => ['nullable', 'in:with,without'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);

        $coaches = User::coaches()
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%'.$request->input('search').'%';
                $q->where(fn ($q) => $q->where('name', 'like', $term)->orWhere('email', 'like', $term)->orWhere('mobile', 'like', $term));
            })
            ->when($request->filled('coach_type'), fn ($q) => $q->where('coach_type', $request->input('coach_type')))
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->input('status')))
            ->when($request->input('plan') === 'with', fn ($q) => $q->whereHas('subscriptions', fn ($s) => $s->current()))
            ->when($request->input('plan') === 'without', fn ($q) => $q->whereDoesntHave('subscriptions', fn ($s) => $s->current()))
            ->with('currentSubscription.plan')
            ->withCount(['customers', 'habits'])
            ->latest()
            ->paginate($request->integer('per_page', 20));

        return CoachResource::collection($coaches);
    }

    public function store(CoachRequest $request): JsonResponse
    {
        $coach = DB::transaction(function () use ($request) {
            $coach = User::create($request->attributesToSave());
            $coach->adoptMasterHabits();

            return $coach;
        });

        return (new CoachResource($coach->loadCount(['customers', 'habits'])))->response()->setStatusCode(201);
    }

    public function show(User $coach): JsonResponse
    {
        $this->ensureCoach($coach);
        $coach->loadCount(['customers', 'habits']);

        return response()->json([
            'data' => new CoachResource($coach),
            'subscriptions' => SubscriptionResource::collection($coach->subscriptions()->with('plan')->latest()->get()),
        ]);
    }

    public function update(CoachRequest $request, User $coach): CoachResource
    {
        $this->ensureCoach($coach);
        $coach->update($request->attributesToSave());

        if ($coach->status === 'inactive') {
            $coach->tokens()->delete();
        }

        return new CoachResource($coach->loadCount(['customers', 'habits']));
    }

    public function destroy(User $coach): JsonResponse
    {
        $this->ensureCoach($coach);
        $coach->customers->each(fn ($customer) => $customer->photos->each->delete());
        $coach->delete();

        return response()->json(null, 204);
    }

    public function assignPlan(Request $request, User $coach, SubscriptionService $subscriptions): JsonResponse
    {
        $this->ensureCoach($coach);
        $data = $request->validate([
            'plan_id' => ['required', 'integer', 'exists:plans,id'],
            'duration_days' => ['nullable', 'integer', 'between:1,3650'],
            'amount' => ['nullable', 'numeric', 'min:0'],
            'starts_at' => ['nullable', 'date_format:Y-m-d'],
            'notes' => ['nullable', 'string', 'max:255'],
        ]);

        $subscription = $subscriptions->assignManually(
            $coach,
            Plan::findOrFail($data['plan_id']),
            $data['duration_days'] ?? null,
            (int) round(($data['amount'] ?? 0) * 100),
            $data['notes'] ?? 'Assigned by admin',
            isset($data['starts_at']) ? Carbon::parse($data['starts_at'])->startOfDay() : null,
        );

        return (new SubscriptionResource($subscription))->response()->setStatusCode(201);
    }

    private function ensureCoach(User $user): void
    {
        abort_unless($user->isCoach(), 404);
    }
}
