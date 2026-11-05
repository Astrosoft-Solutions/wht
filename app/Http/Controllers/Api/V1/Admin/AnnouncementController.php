<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\AnnouncementResource;
use App\Models\Announcement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AnnouncementController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return AnnouncementResource::collection(
            Announcement::withCount('readers')->latest('id')->paginate(20)
        );
    }

    public function store(Request $request): JsonResponse
    {
        $announcement = new Announcement($this->validated($request, creating: true));
        $announcement->published_at ??= now();
        $announcement->created_by = $request->user()->id;
        $announcement->save();

        return (new AnnouncementResource($announcement->loadCount('readers')))->response()->setStatusCode(201);
    }

    public function update(Request $request, Announcement $announcement): AnnouncementResource
    {
        $announcement->update($this->validated($request, creating: false));

        return new AnnouncementResource($announcement->loadCount('readers'));
    }

    public function destroy(Announcement $announcement): JsonResponse
    {
        $announcement->delete();

        return response()->json(null, 204);
    }

    private function validated(Request $request, bool $creating): array
    {
        $required = $creating ? 'required' : 'sometimes';

        return $request->validate([
            'title' => [$required, 'string', 'max:150'],
            'body' => [$required, 'string', 'max:5000'],
            'audience' => ['sometimes', 'in:all,consultant,coach,guide'],
            'published_at' => ['sometimes', 'nullable', 'date'],
            'is_active' => ['sometimes', 'boolean'],
        ]);
    }
}
