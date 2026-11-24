<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// The React admin panel: built from admin/ into public/admin-app, opened at /admin. Every /admin URL
// is a client-side route, so it gets the SPA's index.html.
Route::get('/admin/{any?}', function () {
    $index = public_path('admin-app/index.html');
    abort_unless(is_file($index), 404, 'Admin panel not built. Run "npm run build" in the admin folder.');

    return response()->file($index, ['Cache-Control' => 'no-cache']);
})->where('any', '.*');
