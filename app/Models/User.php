<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    public const ROLE_SUPERADMIN = 'superadmin';
    public const ROLE_COACH = 'coach';

    /**
     * Mirrors the column defaults so freshly created models report them without a refresh.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'role' => self::ROLE_COACH,
        'status' => 'active',
    ];

    /**
     * `role` is deliberately not mass assignable; it is only set with forceFill.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'mobile',
        'password',
        'google_id',
        'avatar_path',
        'coach_type',
        'status',
    ];

    /**
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'google_id',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function habits(): HasMany
    {
        return $this->hasMany(Habit::class);
    }

    public function habitLogs(): HasMany
    {
        return $this->hasMany(HabitLog::class);
    }

    public function customers(): HasMany
    {
        return $this->hasMany(Customer::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function readAnnouncements(): BelongsToMany
    {
        return $this->belongsToMany(Announcement::class, 'announcement_reads')->withPivot('read_at');
    }

    public function scopeCoaches(Builder $query): Builder
    {
        return $query->where('role', self::ROLE_COACH);
    }

    public function isSuperadmin(): bool
    {
        return $this->role === self::ROLE_SUPERADMIN;
    }

    public function isCoach(): bool
    {
        return $this->role === self::ROLE_COACH;
    }

    public function isActive(): bool
    {
        return $this->status !== 'inactive';
    }

    /**
     * Eager-loadable version of activeSubscription() for lists.
     */
    public function currentSubscription(): HasOne
    {
        return $this->hasOne(Subscription::class)->ofMany(
            ['ends_at' => 'max'],
            fn (Builder $q) => $q->where('status', Subscription::STATUS_ACTIVE)
                ->where('starts_at', '<=', now())
                ->where('ends_at', '>', now()),
        );
    }

    public function activeSubscription(): ?Subscription
    {
        return $this->subscriptions()->current()->with('plan')->latest('ends_at')->first();
    }

    public function plan(): ?Plan
    {
        return $this->activeSubscription()?->plan;
    }

    /**
     * Why this coach may not add another customer, or null when allowed.
     */
    public function customerLimitReason(): ?string
    {
        $plan = $this->plan();
        if (! $plan) {
            return 'You need an active plan to add customers. Choose a Gold, Silver or Bronze plan to continue.';
        }
        if ($plan->max_customers !== null && $this->customers()->count() >= $plan->max_customers) {
            return "Your {$plan->name} plan allows up to {$plan->max_customers} customers. Upgrade your plan to add more.";
        }

        return null;
    }

    /**
     * Copies every active master habit into this user's own habits.
     */
    public function adoptMasterHabits(): int
    {
        $count = 0;
        foreach (MasterHabit::active()->ordered()->get() as $template) {
            $this->habits()->create($template->toHabitAttributes());
            $count++;
        }

        return $count;
    }

    public function avatarUrl(): ?string
    {
        if (! $this->avatar_path) {
            return null;
        }

        return str_starts_with($this->avatar_path, 'http')
            ? $this->avatar_path
            : Storage::disk('public')->url($this->avatar_path);
    }
}
