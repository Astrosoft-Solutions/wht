<?php

use App\Http\Controllers\Api\V1\Admin;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ContentController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\HabitController;
use App\Http\Controllers\Api\V1\MeasurementController;
use App\Http\Controllers\Api\V1\PhotoController;
use App\Http\Controllers\Api\V1\PlanController;
use App\Http\Controllers\Api\V1\ProgrammeController;
use App\Http\Controllers\Api\V1\RazorpayWebhookController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\SubscriptionController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::middleware('throttle:10,1')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
        Route::post('auth/google', [AuthController::class, 'google']);
        Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('reset-password', [AuthController::class, 'resetPassword']);
    });

    Route::post('razorpay/webhook', RazorpayWebhookController::class);

    Route::middleware(['auth:sanctum', 'active'])->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::put('me', [AuthController::class, 'updateProfile']);
        Route::delete('me', [AuthController::class, 'deleteAccount']);
        Route::put('me/password', [AuthController::class, 'changePassword']);
        Route::post('me/avatar', [AuthController::class, 'uploadAvatar']);
        Route::delete('me/avatar', [AuthController::class, 'deleteAvatar']);
        Route::post('logout', [AuthController::class, 'logout']);

        Route::get('settings/app', [ContentController::class, 'appSettings']);

        Route::middleware('role:coach')->group(function () {
            Route::get('dashboard', DashboardController::class);
            Route::get('reports', ReportController::class);

            Route::get('habits/schedule', [HabitController::class, 'schedule']);
            Route::post('habits/complete-all', [HabitController::class, 'completeAll']);
            Route::post('habits/from-master', [ContentController::class, 'adoptMasterHabits']);
            Route::post('habits/{habit}/toggle', [HabitController::class, 'toggle']);
            Route::apiResource('habits', HabitController::class);
            Route::get('master-habits', [ContentController::class, 'masterHabits']);

            Route::get('customers/next-code', [CustomerController::class, 'nextCode']);
            Route::patch('customers/{customer}/notes', [CustomerController::class, 'updateNotes']);
            Route::apiResource('customers', CustomerController::class);

            Route::scopeBindings()->prefix('customers/{customer}')->group(function () {
                Route::apiResource('programmes', ProgrammeController::class)->except('show');
                Route::apiResource('measurements', MeasurementController::class)->except('show');
                Route::apiResource('photos', PhotoController::class)->only(['index', 'store', 'destroy']);
            });

            Route::get('plans', [PlanController::class, 'index']);
            Route::get('subscription', [SubscriptionController::class, 'show']);
            Route::post('subscriptions/checkout', [SubscriptionController::class, 'checkout']);
            Route::post('subscriptions/verify', [SubscriptionController::class, 'verify']);

            Route::get('gallery', [ContentController::class, 'gallery']);
            Route::get('announcements', [ContentController::class, 'announcements']);
            Route::post('announcements/read-all', [ContentController::class, 'markAllAnnouncementsRead']);
            Route::post('announcements/{announcement}/read', [ContentController::class, 'markAnnouncementRead']);
        });

        Route::middleware('role:superadmin')->prefix('admin')->group(function () {
            Route::get('dashboard', Admin\DashboardController::class);

            Route::post('coaches/{coach}/assign-plan', [Admin\CoachController::class, 'assignPlan']);
            Route::apiResource('coaches', Admin\CoachController::class);

            Route::apiResource('plans', Admin\PlanController::class)->except('show');

            Route::get('subscriptions', [Admin\SubscriptionController::class, 'index']);
            Route::post('subscriptions/{subscription}/cancel', [Admin\SubscriptionController::class, 'cancel']);
            Route::get('payments', [Admin\SubscriptionController::class, 'payments']);

            Route::apiResource('master-habits', Admin\MasterHabitController::class)->except('show');
            Route::apiResource('gallery', Admin\GalleryController::class)->except('show');
            Route::apiResource('announcements', Admin\AnnouncementController::class)->except('show');

            Route::get('settings', [Admin\SettingsController::class, 'show']);
            Route::put('settings', [Admin\SettingsController::class, 'update']);
        });
    });
});
