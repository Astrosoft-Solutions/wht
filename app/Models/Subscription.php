<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Subscription extends Model
{
    /** @use HasFactory<\Database\Factories\SubscriptionFactory> */
    use HasFactory;

    public const STATUS_PENDING = 'pending';
    public const STATUS_ACTIVE = 'active';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'plan_id',
        'status',
        'starts_at',
        'ends_at',
        'amount_paise',
        'currency',
        'source',
        'razorpay_order_id',
        'razorpay_payment_id',
        'razorpay_signature',
        'notes',
    ];

    protected $hidden = ['razorpay_signature'];

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'amount_paise' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(Plan::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    /**
     * Paid or assigned and covering the current moment.
     */
    public function scopeCurrent(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_ACTIVE)
            ->where('starts_at', '<=', now())
            ->where('ends_at', '>', now());
    }

    /**
     * Active now or queued to start after the current period (renewals).
     */
    public function scopeActiveOrUpcoming(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_ACTIVE)->where('ends_at', '>', now());
    }

    public function isCurrent(): bool
    {
        return $this->status === self::STATUS_ACTIVE
            && $this->starts_at?->lte(now())
            && $this->ends_at?->gt(now());
    }

    public function daysLeft(): int
    {
        if (! $this->ends_at || $this->ends_at->isPast()) {
            return 0;
        }

        return (int) ceil(now()->diffInHours($this->ends_at) / 24);
    }
}
