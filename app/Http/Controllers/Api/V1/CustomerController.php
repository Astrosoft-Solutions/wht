<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CustomerRequest;
use App\Http\Resources\CustomerResource;
use App\Models\Customer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class CustomerController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:active,inactive'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);

        $customers = $request->user()->customers()
            ->search($request->input('search'))
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->input('status')))
            ->with('latestMeasurement')
            ->orderBy('customer_code')
            ->paginate($request->integer('per_page', 20));

        return CustomerResource::collection($customers);
    }

    public function nextCode(Request $request): JsonResponse
    {
        return response()->json(['customer_code' => Customer::nextCodeFor($request->user()->id)]);
    }

    public function store(CustomerRequest $request): JsonResponse
    {
        if ($reason = $request->user()->customerLimitReason()) {
            return response()->json(['message' => $reason, 'code' => 'plan_limit'], 403);
        }

        $customer = DB::transaction(function () use ($request) {
            $customer = $request->user()->customers()->create($request->customerData());

            $measurement = array_filter($request->measurementData(), fn ($v) => $v !== null);
            if ($measurement) {
                $customer->measurements()->create($measurement + ['recorded_on' => now()->toDateString()]);
            }

            return $customer;
        });

        return (new CustomerResource($this->loadDetail($customer)))->response()->setStatusCode(201);
    }

    public function show(Customer $customer): CustomerResource
    {
        Gate::authorize('view', $customer);

        return new CustomerResource($this->loadDetail($customer));
    }

    public function update(CustomerRequest $request, Customer $customer): CustomerResource
    {
        Gate::authorize('update', $customer);

        DB::transaction(function () use ($request, $customer) {
            $customer->update($request->customerData());

            $measurement = $request->measurementData();
            if ($measurement) {
                $baseline = $customer->baselineMeasurement()->first();
                if ($baseline) {
                    $baseline->fill($measurement);
                    if (! array_key_exists('bmi', $measurement) && $baseline->isDirty('weight')) {
                        $baseline->bmi = null;
                    }
                    $baseline->save();
                } elseif (array_filter($measurement, fn ($v) => $v !== null)) {
                    $customer->measurements()->create($measurement + ['recorded_on' => now()->toDateString()]);
                }
            }
        });

        return new CustomerResource($this->loadDetail($customer->refresh()));
    }

    public function updateNotes(Request $request, Customer $customer): CustomerResource
    {
        Gate::authorize('update', $customer);

        $customer->update($request->validate([
            'health_condition_before' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'remarks' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ]));

        return new CustomerResource($this->loadDetail($customer));
    }

    public function destroy(Customer $customer): JsonResponse
    {
        Gate::authorize('delete', $customer);

        $customer->photos->each->delete();
        $customer->delete();

        return response()->json(null, 204);
    }

    private function loadDetail(Customer $customer): Customer
    {
        return $customer->load(['baselineMeasurement', 'latestMeasurement', 'programmes', 'photos']);
    }
}
