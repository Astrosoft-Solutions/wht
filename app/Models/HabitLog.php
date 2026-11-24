<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HabitLog extends Model
{
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_MISSED = 'missed';

    protected $fillable = [
        'habit_id',
        'user_id',
        'log_date',
        'status',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'log_date' => 'date:Y-m-d',
            'completed_at' => 'datetime',
        ];
    }

    public function habit(): BelongsTo
    {
        return $this->belongsTo(Habit::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
