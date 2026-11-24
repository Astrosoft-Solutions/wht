<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class GalleryItem extends Model
{
    protected $fillable = [
        'type',
        'title',
        'description',
        'path',
        'video_url',
        'thumbnail_path',
        'is_published',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'is_published' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::deleted(function (GalleryItem $item) {
            Storage::disk('public')->delete(array_filter([$item->path, $item->thumbnail_path]));
        });
    }

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('is_published', true);
    }

    public function fileUrl(): ?string
    {
        return $this->path ? Storage::disk('public')->url($this->path) : null;
    }

    public function thumbnailUrl(): ?string
    {
        if ($this->thumbnail_path) {
            return Storage::disk('public')->url($this->thumbnail_path);
        }
        if ($this->type === 'image') {
            return $this->fileUrl();
        }
        $youtubeId = $this->youtubeId();

        return $youtubeId ? "https://img.youtube.com/vi/{$youtubeId}/hqdefault.jpg" : null;
    }

    public function youtubeId(): ?string
    {
        if (! $this->video_url) {
            return null;
        }
        preg_match('~(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|shorts/))([\w-]{11})~', $this->video_url, $m);

        return $m[1] ?? null;
    }
}
