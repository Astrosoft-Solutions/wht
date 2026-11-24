<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\GalleryItemRequest;
use App\Http\Resources\GalleryItemResource;
use App\Models\GalleryItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Storage;

class GalleryController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'type' => ['nullable', 'in:image,video'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);

        $items = GalleryItem::query()
            ->when($request->filled('type'), fn ($q) => $q->where('type', $request->input('type')))
            ->orderBy('sort_order')
            ->latest('id')
            ->paginate($request->integer('per_page', 24));

        return GalleryItemResource::collection($items);
    }

    public function store(GalleryItemRequest $request): JsonResponse
    {
        $item = new GalleryItem($request->safe()->except(['file', 'thumbnail']));
        $item->uploaded_by = $request->user()->id;
        $this->storeFiles($request, $item);
        $item->save();

        return (new GalleryItemResource($item->refresh()))->response()->setStatusCode(201);
    }

    /**
     * Sent as POST with _method=PUT, because PHP only parses multipart bodies on POST.
     */
    public function update(GalleryItemRequest $request, GalleryItem $gallery): GalleryItemResource
    {
        $gallery->fill($request->safe()->except(['file', 'thumbnail']));
        if ($request->hasFile('file') && $gallery->type === 'video') {
            $gallery->video_url = null;
        }
        if ($request->filled('video_url') && $gallery->path) {
            Storage::disk('public')->delete($gallery->path);
            $gallery->path = null;
        }
        $this->storeFiles($request, $gallery);
        $gallery->save();

        return new GalleryItemResource($gallery);
    }

    public function destroy(GalleryItem $gallery): JsonResponse
    {
        $gallery->delete();

        return response()->json(null, 204);
    }

    private function storeFiles(Request $request, GalleryItem $item): void
    {
        if ($request->hasFile('file')) {
            if ($item->path) {
                Storage::disk('public')->delete($item->path);
            }
            $item->path = $request->file('file')->store('gallery/'.$item->type.'s', 'public');
        }
        if ($request->hasFile('thumbnail')) {
            if ($item->thumbnail_path) {
                Storage::disk('public')->delete($item->thumbnail_path);
            }
            $item->thumbnail_path = $request->file('thumbnail')->store('gallery/thumbnails', 'public');
        }
    }
}
