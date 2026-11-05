<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class CustomerPhoto extends Model
{
    protected $fillable = [
        'type',
        'path',
        'taken_on',
    ];

    protected function casts(): array
    {
        return [
            'taken_on' => 'date:Y-m-d',
        ];
    }

    protected static function booted(): void
    {
        static::deleted(function (CustomerPhoto $photo) {
            Storage::disk('public')->delete($photo->path);
        });
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function url(): string
    {
        return Storage::disk('public')->url($this->path);
    }
}
