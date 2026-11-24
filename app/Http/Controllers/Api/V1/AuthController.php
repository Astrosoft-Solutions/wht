<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Plan;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'mobile' => ['nullable', 'string', 'max:20', 'unique:users,mobile'],
            'password' => ['required', 'confirmed', PasswordRule::min(6)],
            'coach_type' => ['nullable', Rule::in(Plan::COACH_TYPES)],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::create(['coach_type' => 'coach', ...array_filter($data, fn ($v) => $v !== null)]);
        $user->adoptMasterHabits();

        return $this->tokenResponse($user, $data['device_name'] ?? null, 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'login' => ['required', 'string'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $field = filter_var($data['login'], FILTER_VALIDATE_EMAIL) ? 'email' : 'mobile';
        $user = User::where($field, $data['login'])->first();

        if (! $user || ! $user->password || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['These credentials do not match our records.'],
            ]);
        }

        return $this->tokenResponse($user, $data['device_name'] ?? null);
    }

    public function google(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_token' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $data['id_token'],
        ]);

        $payload = $response->json();
        $allowedAudiences = config('services.google.client_ids');

        if (
            ! $response->successful()
            || empty($payload['sub'])
            || empty($payload['email'])
            || ($payload['email_verified'] ?? 'false') !== 'true'
            || ($allowedAudiences && ! in_array($payload['aud'] ?? null, $allowedAudiences, true))
        ) {
            throw ValidationException::withMessages([
                'id_token' => ['Unable to verify Google sign-in.'],
            ]);
        }

        $user = User::where('google_id', $payload['sub'])->first()
            ?? User::where('email', $payload['email'])->first();

        if ($user) {
            $user->forceFill([
                'google_id' => $payload['sub'],
                'avatar_path' => $user->avatar_path ?? ($payload['picture'] ?? null),
            ])->save();
        } else {
            $user = User::create([
                'name' => $payload['name'] ?? Str::before($payload['email'], '@'),
                'email' => $payload['email'],
                'google_id' => $payload['sub'],
                'avatar_path' => $payload['picture'] ?? null,
                'coach_type' => 'coach',
            ]);
            $user->forceFill(['email_verified_at' => now()])->save();
            $user->adoptMasterHabits();
        }

        return $this->tokenResponse($user, $data['device_name'] ?? null);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['email' => ['required', 'email']]);

        Password::sendResetLink($request->only('email'));

        return response()->json([
            'message' => 'If that email is registered, a password reset link has been sent.',
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'confirmed', PasswordRule::min(6)],
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password) {
                $user->forceFill(['password' => $password])->save();
                $user->tokens()->delete();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['email' => [__($status)]]);
        }

        return response()->json(['message' => __($status)]);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user());
    }

    public function updateProfile(Request $request): UserResource
    {
        $user = $request->user();

        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'mobile' => ['sometimes', 'nullable', 'string', 'max:20', 'unique:users,mobile,'.$user->id],
        ]);

        $user->update($data);

        return new UserResource($user);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            // Accounts created with Google have no password yet, so they can set one without the old one.
            'current_password' => [$user->password ? 'required' : 'nullable', 'string'],
            'password' => ['required', 'confirmed', PasswordRule::min(6)],
        ]);

        if ($user->password && ! Hash::check($data['current_password'], $user->password)) {
            throw ValidationException::withMessages(['current_password' => ['Your current password is incorrect.']]);
        }

        $user->forceFill(['password' => $data['password']])->save();
        $user->tokens()->where('id', '!=', $user->currentAccessToken()?->getKey())->delete();

        return response()->json(['message' => 'Password updated. Other devices have been signed out.']);
    }

    public function uploadAvatar(Request $request): UserResource
    {
        $request->validate(['avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048']]);
        $user = $request->user();

        $this->deleteStoredAvatar($user);
        $user->forceFill(['avatar_path' => $request->file('avatar')->store('avatars', 'public')])->save();

        return new UserResource($user);
    }

    public function deleteAvatar(Request $request): UserResource
    {
        $user = $request->user();
        $this->deleteStoredAvatar($user);
        $user->forceFill(['avatar_path' => null])->save();

        return new UserResource($user);
    }

    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user->isSuperadmin()) {
            return response()->json(['message' => 'Superadmin accounts cannot be deleted from the app.'], 403);
        }

        $request->validate($user->password
            ? ['password' => ['required', 'string']]
            : ['confirm' => ['required', 'in:DELETE']]);

        if ($user->password && ! Hash::check($request->input('password'), $user->password)) {
            throw ValidationException::withMessages(['password' => ['Your password is incorrect.']]);
        }

        $user->customers->each(fn ($customer) => $customer->photos->each->delete());
        $this->deleteStoredAvatar($user);
        $user->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'Your account has been deleted.']);
    }

    private function deleteStoredAvatar(User $user): void
    {
        if ($user->avatar_path && ! str_starts_with($user->avatar_path, 'http')) {
            Storage::disk('public')->delete($user->avatar_path);
        }
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    private function tokenResponse(User $user, ?string $deviceName, int $status = 200): JsonResponse
    {
        if (! $user->isActive()) {
            throw ValidationException::withMessages([
                'login' => ['Your account has been deactivated. Please contact support.'],
            ]);
        }

        $token = $user->createToken($deviceName ?: 'mobile-app')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => new UserResource($user),
        ], $status);
    }
}
