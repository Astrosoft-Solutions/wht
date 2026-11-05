<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\AnnouncementResource;
use App\Http\Resources\GalleryItemResource;
use App\Http\Resources\HabitResource;
use App\Http\Resources\MasterHabitResource;
use App\Models\Announcement;
use App\Models\AppSetting;
use App\Models\GalleryItem;
use App\Models\MasterHabit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

/**
 * Content managed by the superadmin and read by coaches in the mobile app.
 */
class ContentController extends Controller
{
    public function masterHabits(): AnonymousResourceCollection
    {
        return MasterHabitResource::collection(MasterHabit::active()->ordered()->get());
    }

    public function adoptMasterHabits(Request $request): JsonResponse
    {
        $data = $request->validate([
            'master_habit_ids' => ['required', 'array', 'min:1'],
            'master_habit_ids.*' => ['integer', 'distinct', 'exists:master_habits,id'],
        ]);

        $user = $request->user();
        $habits = MasterHabit::active()->whereIn('id', $data['master_habit_ids'])->ordered()->get()
            ->map(fn (MasterHabit $template) => $user->habits()->create($template->toHabitAttributes()));

        return HabitResource::collection($habits)->response()->setStatusCode(201);
    }

    public function gallery(Request $request): AnonymousResourceCollection
    {
        $request->validate(['type' => ['nullable', 'in:image,video']]);

        $items = GalleryItem::published()
            ->when($request->filled('type'), fn ($q) => $q->where('type', $request->input('type')))
            ->orderBy('sort_order')
            ->latest('id')
            ->paginate(24);

        return GalleryItemResource::collection($items);
    }

    public function announcements(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();

        $items = Announcement::visibleTo($user)
            ->select('announcements.*')
            ->selectRaw('EXISTS (SELECT 1 FROM announcement_reads r WHERE r.announcement_id = announcements.id AND r.user_id = ?) AS is_read', [$user->id])
            ->orderByDesc(DB::raw('COALESCE(published_at, created_at)'))
            ->limit(50)
            ->get();

        return AnnouncementResource::collection($items)->additional([
            'unread_count' => $items->where('is_read', false)->count(),
        ]);
    }

    public function markAnnouncementRead(Request $request, Announcement $announcement): JsonResponse
    {
        $user = $request->user();
        abort_unless(Announcement::visibleTo($user)->whereKey($announcement->id)->exists(), 404);

        $announcement->readers()->syncWithoutDetaching([$user->id => ['read_at' => now()]]);

        return response()->json(['message' => 'Marked as read.']);
    }

    public function markAllAnnouncementsRead(Request $request): JsonResponse
    {
        $user = $request->user();
        $ids = Announcement::visibleTo($user)->pluck('id');
        $user->readAnnouncements()
            ->syncWithoutDetaching($ids->mapWithKeys(fn ($id) => [$id => ['read_at' => now()]])->all());

        return response()->json(['message' => 'All announcements marked as read.']);
    }

    public function appSettings(): JsonResponse
    {
        return response()->json(['data' => AppSetting::reminderSettings()]);
    }
}
