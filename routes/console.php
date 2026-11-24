<?php

use App\Services\SubscriptionService;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('subscriptions:expire', function (SubscriptionService $subscriptions) {
    $this->info($subscriptions->expireOverdue().' subscription(s) marked as expired.');
})->purpose('Mark subscriptions whose period has ended as expired');

Schedule::command('subscriptions:expire')->hourly();
