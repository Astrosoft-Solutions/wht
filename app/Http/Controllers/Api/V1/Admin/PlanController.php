<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\PlanRequest;
use App\Http\Resources\PlanResource;
use App\Models\Plan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PlanController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return PlanResource::collection(Plan::withCount('subscriptions')->ordered()->get());
    }

    public function store(PlanRequest $request): JsonResponse
    {
        $plan = Plan::create($request->attributesToSave());

        return (new PlanResource($plan->refresh()))->response()->setStatusCode(201);
    }

    public function update(PlanRequest $request, Plan $plan): PlanResource
    {
        $plan->update($request->attributesToSave());

        return new PlanResource($plan->loadCount('subscriptions'));
    }

    public function destroy(Plan $plan): JsonResponse
    {
        if ($plan->subscriptions()->exists()) {
            return response()->json([
                'message' => 'This plan has subscriptions, so it cannot be deleted. Deactivate it instead.',
            ], 422);
        }

        $plan->delete();

        return response()->json(null, 204);
    }
}
