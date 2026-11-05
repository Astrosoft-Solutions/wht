<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\MeasurementRequest;
use App\Http\Resources\MeasurementResource;
use App\Models\Customer;
use App\Models\CustomerMeasurement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

class MeasurementController extends Controller
{
    public function index(Request $request, Customer $customer): AnonymousResourceCollection
    {
        Gate::authorize('view', $customer);
        $request->validate(['programme_id' => ['nullable', 'integer']]);

        $measurements = $customer->measurements()
            ->when($request->filled('programme_id'), fn ($q) => $q->where('programme_id', $request->integer('programme_id')))
            ->orderBy('recorded_on')
            ->orderBy('id')
            ->get();

        return MeasurementResource::collection($measurements);
    }

    public function store(MeasurementRequest $request, Customer $customer): JsonResponse
    {
        Gate::authorize('update', $customer);

        $measurement = $customer->measurements()->create($request->validated());

        return (new MeasurementResource($measurement->refresh()))->response()->setStatusCode(201);
    }

    public function update(MeasurementRequest $request, Customer $customer, CustomerMeasurement $measurement): MeasurementResource
    {
        Gate::authorize('update', $customer);

        $data = $request->validated();
        $measurement->fill($data);
        if (! array_key_exists('bmi', $data) && $measurement->isDirty('weight')) {
            $measurement->bmi = null;
        }
        $measurement->save();

        return new MeasurementResource($measurement);
    }

    public function destroy(Customer $customer, CustomerMeasurement $measurement): JsonResponse
    {
        Gate::authorize('update', $customer);

        $measurement->delete();

        return response()->json(null, 204);
    }
}
