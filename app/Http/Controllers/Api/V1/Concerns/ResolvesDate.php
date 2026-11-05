<?php

namespace App\Http\Controllers\Api\V1\Concerns;

use Carbon\CarbonImmutable;
use Illuminate\Http\Request;

trait ResolvesDate
{
    /**
     * The client sends its local calendar date so "today" matches the device, not the server timezone.
     */
    protected function resolveDate(Request $request, string $key = 'date'): CarbonImmutable
    {
        $request->validate([$key => ['nullable', 'date_format:Y-m-d']]);

        return $request->filled($key)
            ? CarbonImmutable::createFromFormat('Y-m-d', $request->input($key))->startOfDay()
            : CarbonImmutable::today();
    }
}
