<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\PlanResource;
use App\Models\Plan;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class PlanController extends Controller
{
    /**
     * Active plans for the coach's own type unless another type is requested.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['coach_type' => ['nullable', Rule::in([...Plan::COACH_TYPES, 'all'])]]);
        $type = $request->input('coach_type', $request->user()->coach_type ?? 'all');

        $plans = Plan::active()
            ->when($type !== 'all', fn ($q) => $q->where('coach_type', $type))
            ->ordered()
            ->get();

        return PlanResource::collection($plans);
    }
}
