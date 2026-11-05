<?php

namespace Tests\Feature;

use App\Models\Announcement;
use App\Models\AppSetting;
use App\Models\GalleryItem;
use App\Models\MasterHabit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RoleAndContentTest extends TestCase
{
    use RefreshDatabase;

    public function test_coach_cannot_open_admin_api_and_superadmin_cannot_use_coach_api(): void
    {
        Sanctum::actingAs(User::factory()->coach()->create());
        $this->getJson('/api/v1/admin/dashboard')->assertForbidden();

        Sanctum::actingAs(User::factory()->superadmin()->create());
        $this->getJson('/api/v1/admin/dashboard')->assertOk();
        $this->getJson('/api/v1/habits')->assertForbidden();
    }

    public function test_login_returns_role_and_inactive_users_cannot_sign_in(): void
    {
        User::factory()->superadmin()->create(['email' => 'admin@example.com']);
        User::factory()->coach()->create(['email' => 'off@example.com', 'status' => 'inactive']);

        $this->postJson('/api/v1/login', ['login' => 'admin@example.com', 'password' => 'password'])
            ->assertOk()
            ->assertJsonPath('user.role', 'superadmin');

        $this->postJson('/api/v1/login', ['login' => 'off@example.com', 'password' => 'password'])
            ->assertUnprocessable();
    }

    public function test_deactivated_user_token_stops_working(): void
    {
        $coach = User::factory()->coach()->create(['status' => 'inactive']);
        Sanctum::actingAs($coach);

        $this->getJson('/api/v1/me')->assertForbidden();
    }

    public function test_registration_copies_master_habits(): void
    {
        MasterHabit::create(['name' => 'Water', 'start_time' => '08:00', 'is_active' => true]);
        MasterHabit::create(['name' => 'Old', 'start_time' => '09:00', 'is_active' => false]);

        $this->postJson('/api/v1/register', [
            'name' => 'New Coach',
            'email' => 'new@example.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
            'coach_type' => 'guide',
        ])->assertCreated()->assertJsonPath('user.coach_type', 'guide');

        $user = User::where('email', 'new@example.com')->first();
        $this->assertSame(['Water'], $user->habits()->pluck('name')->all());
    }

    public function test_coach_can_add_habits_from_templates(): void
    {
        $template = MasterHabit::create(['name' => 'Prayer Time', 'icon' => 'prayer', 'start_time' => '04:20', 'end_time' => '04:45']);
        Sanctum::actingAs(User::factory()->coach()->create());

        $this->getJson('/api/v1/master-habits')->assertOk()->assertJsonPath('data.0.name', 'Prayer Time');
        $this->postJson('/api/v1/habits/from-master', ['master_habit_ids' => [$template->id]])
            ->assertCreated()
            ->assertJsonPath('data.0.start_time', '04:20');
    }

    public function test_gallery_shows_only_published_items(): void
    {
        GalleryItem::create(['type' => 'video', 'title' => 'Yoga', 'video_url' => 'https://youtu.be/abcdefghijk', 'is_published' => true]);
        GalleryItem::create(['type' => 'image', 'title' => 'Draft', 'path' => 'gallery/x.jpg', 'is_published' => false]);
        Sanctum::actingAs(User::factory()->coach()->create());

        $this->getJson('/api/v1/gallery')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.youtube_id', 'abcdefghijk')
            ->assertJsonPath('data.0.thumbnail_url', 'https://img.youtube.com/vi/abcdefghijk/hqdefault.jpg');
    }

    public function test_announcements_respect_audience_and_track_reads(): void
    {
        $all = Announcement::create(['title' => 'All', 'body' => 'x', 'audience' => 'all', 'published_at' => now()->subMinute()]);
        Announcement::create(['title' => 'Guides', 'body' => 'x', 'audience' => 'guide', 'published_at' => now()->subMinute()]);
        Announcement::create(['title' => 'Future', 'body' => 'x', 'audience' => 'all', 'published_at' => now()->addDay()]);
        Sanctum::actingAs(User::factory()->coach('coach')->create());

        $this->getJson('/api/v1/announcements')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('unread_count', 1);

        $this->postJson("/api/v1/announcements/{$all->id}/read")->assertOk();

        $this->getJson('/api/v1/announcements')
            ->assertJsonPath('data.0.is_read', true)
            ->assertJsonPath('unread_count', 0);
    }

    public function test_app_settings_return_reminder_rules(): void
    {
        AppSetting::putMany(['reminder_lead_minutes' => 10, 'reminders_default_on' => false]);
        Sanctum::actingAs(User::factory()->coach()->create());

        $this->getJson('/api/v1/settings/app')
            ->assertOk()
            ->assertJsonPath('data.reminder_lead_minutes', 10)
            ->assertJsonPath('data.reminder_interval_minutes', 15)
            ->assertJsonPath('data.reminders_default_on', false);
    }
}
