<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Announcement */
class AnnouncementResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $attributes = $this->resource->getAttributes();

        return [
            'id' => $this->id,
            'title' => $this->title,
            'body' => $this->body,
            'audience' => $this->audience,
            'published_at' => ($this->published_at ?? $this->created_at)?->toIso8601String(),
            'is_active' => $this->is_active,
            'is_read' => $this->when(array_key_exists('is_read', $attributes), fn () => (bool) $attributes['is_read']),
            'reads_count' => $this->whenCounted('readers'),
        ];
    }
}
