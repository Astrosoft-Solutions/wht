<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\ProgrammeRequest;
use App\Http\Resources\ProgrammeResource;
use App\Models\Customer;
use App\Models\Programme;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

class ProgrammeController extends Controller
{
    public function index(Customer $customer): AnonymousResourceCollection
    {
        Gate::authorize('view', $customer);

        return ProgrammeResource::collection($customer->programmes()->latest('id')->get());
    }

    public function store(ProgrammeRequest $request, Customer $customer): JsonResponse
    {
        Gate::authorize('update', $customer);

        $programme = $customer->programmes()->make($request->validated());
        $this->ensureWeeksValid($programme);
        $programme->save();

        return (new ProgrammeResource($programme->refresh()))->response()->setStatusCode(201);
    }

    public function update(ProgrammeRequest $request, Customer $customer, Programme $programme): ProgrammeResource
    {
        Gate::authorize('update', $customer);

        $programme->fill($request->validated());
        $this->ensureWeeksValid($programme);
        $programme->save();

        return new ProgrammeResource($programme);
    }

    public function destroy(Customer $customer, Programme $programme): JsonResponse
    {
        Gate::authorize('update', $customer);

        $programme->delete();

        return response()->json(null, 204);
    }

    private function ensureWeeksValid(Programme $programme): void
    {
        if (($programme->weeks_completed ?? 0) > ($programme->total_weeks ?? 12)) {
            throw ValidationException::withMessages([
                'weeks_completed' => ['Weeks completed cannot exceed total weeks.'],
            ]);
        }
    }
}
