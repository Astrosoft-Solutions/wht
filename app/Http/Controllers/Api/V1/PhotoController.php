<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\PhotoResource;
use App\Models\Customer;
use App\Models\CustomerPhoto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

class PhotoController extends Controller
{
    public function index(Customer $customer): AnonymousResourceCollection
    {
        Gate::authorize('view', $customer);

        return PhotoResource::collection($customer->photos()->latest('id')->get());
    }

    /**
     * Each customer keeps one "before" and one "after" photo; uploading replaces the previous one of that type.
     */
    public function store(Request $request, Customer $customer): JsonResponse
    {
        Gate::authorize('update', $customer);

        $data = $request->validate([
            'type' => ['required', 'in:before,after'],
            'photo' => ['required', 'image', 'max:5120'],
            'taken_on' => ['nullable', 'date_format:Y-m-d'],
        ]);

        $path = $request->file('photo')->store("customers/{$customer->id}", 'public');

        $customer->photos()->where('type', $data['type'])->get()->each->delete();

        $photo = $customer->photos()->create([
            'type' => $data['type'],
            'path' => $path,
            'taken_on' => $data['taken_on'] ?? now()->toDateString(),
        ]);

        return (new PhotoResource($photo))->response()->setStatusCode(201);
    }

    public function destroy(Customer $customer, CustomerPhoto $photo): JsonResponse
    {
        Gate::authorize('update', $customer);

        $photo->delete();

        return response()->json(null, 204);
    }
}
