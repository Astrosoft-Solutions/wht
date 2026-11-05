<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\MasterHabitRequest;
use App\Http\Resources\MasterHabitResource;
use App\Models\MasterHabit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class MasterHabitController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return MasterHabitResource::collection(MasterHabit::ordered()->get());
    }

    public function store(MasterHabitRequest $request): JsonResponse
    {
        $habit = MasterHabit::create($request->validated());

        return (new MasterHabitResource($habit->refresh()))->response()->setStatusCode(201);
    }

    public function update(MasterHabitRequest $request, MasterHabit $masterHabit): MasterHabitResource
    {
        $masterHabit->update($request->validated());

        return new MasterHabitResource($masterHabit->refresh());
    }

    public function destroy(MasterHabit $masterHabit): JsonResponse
    {
        $masterHabit->delete();

        return response()->json(null, 204);
    }
}
