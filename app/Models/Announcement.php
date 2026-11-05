<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Announcement extends Model
{
    protected $fillable = [
        'title',
        'body',
        'audience',
        'published_at',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
            'is_active' => 'boolean',
        ];
    }

    public function readers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'announcement_reads')->withPivot('read_at');
    }

    /**
     * Active, already published, and addressed to everyone or to the user's coach type.
     */
    public function scopeVisibleTo(Builder $query, User $user): Builder
    {
        return $query->where('is_active', true)
            ->where(fn (Builder $q) => $q->whereNull('published_at')->orWhere('published_at', '<=', now()))
            ->where(fn (Builder $q) => $q->where('audience', 'all')->when(
                $user->coach_type,
                fn (Builder $q) => $q->orWhere('audience', $user->coach_type),
            ));
    }
}
