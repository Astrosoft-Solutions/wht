<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Services\RazorpayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function show(RazorpayService $razorpay): JsonResponse
    {
        return response()->json([
            'data' => AppSetting::reminderSettings(),
            'razorpay_configured' => $razorpay->isConfigured(),
            'razorpay_webhook_configured' => filled(config('services.razorpay.webhook_secret')),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'reminders_default_on' => ['sometimes', 'boolean'],
            'reminder_lead_minutes' => ['sometimes', 'integer', 'between:0,180'],
            'reminder_interval_minutes' => ['sometimes', 'integer', 'between:5,180'],
        ]);

        AppSetting::putMany($data);

        return response()->json(['data' => AppSetting::reminderSettings()]);
    }
}
