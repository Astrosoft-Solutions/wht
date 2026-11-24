<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppSetting extends Model
{
    protected $primaryKey = 'key';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = ['key', 'value'];

    /**
     * Reminder rules the mobile app downloads; values here are the defaults.
     */
    public const REMINDER_DEFAULTS = [
        'reminders_default_on' => true,
        'reminder_lead_minutes' => 15,
        'reminder_interval_minutes' => 15,
    ];

    /**
     * @return array{reminders_default_on: bool, reminder_lead_minutes: int, reminder_interval_minutes: int}
     */
    public static function reminderSettings(): array
    {
        $stored = static::whereIn('key', array_keys(self::REMINDER_DEFAULTS))->pluck('value', 'key');

        return [
            'reminders_default_on' => filter_var($stored['reminders_default_on'] ?? true, FILTER_VALIDATE_BOOLEAN),
            'reminder_lead_minutes' => (int) ($stored['reminder_lead_minutes'] ?? self::REMINDER_DEFAULTS['reminder_lead_minutes']),
            'reminder_interval_minutes' => (int) ($stored['reminder_interval_minutes'] ?? self::REMINDER_DEFAULTS['reminder_interval_minutes']),
        ];
    }

    /**
     * @param  array<string, mixed>  $values
     */
    public static function putMany(array $values): void
    {
        foreach ($values as $key => $value) {
            static::updateOrCreate(['key' => $key], ['value' => is_bool($value) ? ($value ? '1' : '0') : (string) $value]);
        }
    }
}
