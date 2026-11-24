<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AccountTest extends TestCase
{
    use RefreshDatabase;

    public function test_change_password_requires_current_password_and_signs_out_other_devices(): void
    {
        $user = User::factory()->coach()->create();
        $user->createToken('other-device');
        $current = $user->createToken('this-device')->plainTextToken;

        $this->withToken($current)->putJson('/api/v1/me/password', [
            'current_password' => 'wrong',
            'password' => 'newsecret',
            'password_confirmation' => 'newsecret',
        ])->assertUnprocessable()->assertJsonValidationErrors('current_password');

        $this->withToken($current)->putJson('/api/v1/me/password', [
            'current_password' => 'password',
            'password' => 'newsecret',
            'password_confirmation' => 'newsecret',
        ])->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 1);
        $this->postJson('/api/v1/login', ['login' => $user->email, 'password' => 'newsecret'])->assertOk();
    }

    public function test_google_only_account_can_set_a_password_without_current_one(): void
    {
        $user = User::factory()->coach()->create(['password' => null, 'google_id' => 'g-1']);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/me/password', ['password' => 'firstpass', 'password_confirmation' => 'firstpass'])
            ->assertOk();
    }

    public function test_avatar_upload_and_removal(): void
    {
        Storage::fake('public');
        Sanctum::actingAs(User::factory()->coach()->create());

        $url = $this->post('/api/v1/me/avatar', ['avatar' => UploadedFile::fake()->image('me.jpg')], ['Accept' => 'application/json'])
            ->assertOk()
            ->json('data.avatar_url');
        $this->assertNotNull($url);
        $this->assertCount(1, Storage::disk('public')->allFiles('avatars'));

        $this->deleteJson('/api/v1/me/avatar')->assertOk()->assertJsonPath('data.avatar_url', null);
        $this->assertCount(0, Storage::disk('public')->allFiles('avatars'));
    }

    public function test_delete_account_requires_password_and_removes_data(): void
    {
        $user = User::factory()->withPlan()->create();
        Customer::factory()->for($user)->create();
        Sanctum::actingAs($user);

        $this->deleteJson('/api/v1/me', ['password' => 'wrong'])->assertUnprocessable();
        $this->deleteJson('/api/v1/me', ['password' => 'password'])->assertOk();

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $this->assertDatabaseCount('customers', 0);
    }

    public function test_inactive_account_gets_machine_readable_code(): void
    {
        Sanctum::actingAs(User::factory()->coach()->create(['status' => 'inactive']));

        $this->getJson('/api/v1/me')->assertForbidden()->assertJsonPath('code', 'account_inactive');
    }

    public function test_reset_link_points_to_panel_reset_page(): void
    {
        Notification::fake();
        $user = User::factory()->coach()->create();

        $this->postJson('/api/v1/forgot-password', ['email' => $user->email])->assertOk();

        Notification::assertSentTo($user, ResetPassword::class, function (ResetPassword $notification) use ($user) {
            $url = $notification->toMail($user)->actionUrl;

            return str_contains($url, '/admin/reset-password?token=');
        });
    }
}
