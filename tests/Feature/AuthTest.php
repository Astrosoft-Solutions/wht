<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_receive_token(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'name' => 'Vignesh',
            'email' => 'v@example.com',
            'mobile' => '9876543210',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ]);

        $response->assertCreated()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email', 'mobile']]);
    }

    public function test_user_can_login_with_email_or_mobile(): void
    {
        User::factory()->create(['email' => 'v@example.com', 'mobile' => '9876543210']);

        $this->postJson('/api/v1/login', ['login' => 'v@example.com', 'password' => 'password'])
            ->assertOk()->assertJsonStructure(['token']);

        $this->postJson('/api/v1/login', ['login' => '9876543210', 'password' => 'password'])
            ->assertOk()->assertJsonStructure(['token']);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create(['email' => 'v@example.com']);

        $this->postJson('/api/v1/login', ['login' => 'v@example.com', 'password' => 'nope'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('login');
    }

    public function test_me_and_logout_use_the_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/me')
            ->assertOk()->assertJsonPath('data.email', $user->email);

        $this->withToken($token)->postJson('/api/v1/logout')->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_google_login_creates_user_from_verified_token(): void
    {
        config(['services.google.client_ids' => ['client-123']]);
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response([
                'sub' => 'google-1',
                'email' => 'g@example.com',
                'email_verified' => 'true',
                'name' => 'Google User',
                'aud' => 'client-123',
            ]),
        ]);

        $this->postJson('/api/v1/auth/google', ['id_token' => 'fake'])
            ->assertOk()
            ->assertJsonPath('user.email', 'g@example.com');

        $this->assertDatabaseHas('users', ['email' => 'g@example.com', 'google_id' => 'google-1']);
    }

    public function test_google_login_rejects_wrong_audience(): void
    {
        config(['services.google.client_ids' => ['client-123']]);
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response([
                'sub' => 'google-1',
                'email' => 'g@example.com',
                'email_verified' => 'true',
                'aud' => 'someone-else',
            ]),
        ]);

        $this->postJson('/api/v1/auth/google', ['id_token' => 'fake'])
            ->assertUnprocessable();
    }

    public function test_forgot_password_always_returns_ok(): void
    {
        $this->postJson('/api/v1/forgot-password', ['email' => 'unknown@example.com'])->assertOk();
    }

    public function test_protected_routes_require_auth(): void
    {
        $this->getJson('/api/v1/dashboard')->assertUnauthorized();
    }
}
