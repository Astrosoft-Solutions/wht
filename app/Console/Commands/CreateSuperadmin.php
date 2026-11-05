<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Validator;

class CreateSuperadmin extends Command
{
    protected $signature = 'app:create-superadmin {email} {--name=Super Admin} {--password=}';

    protected $description = 'Create a superadmin account, or promote an existing user to superadmin';

    public function handle(): int
    {
        $email = $this->argument('email');
        $password = $this->option('password') ?: $this->secret('Password (min 8 characters)');

        $validator = Validator::make(
            ['email' => $email, 'password' => $password],
            ['email' => ['required', 'email'], 'password' => ['required', 'min:8']],
        );
        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $error) {
                $this->error($error);
            }

            return self::FAILURE;
        }

        $user = User::firstOrNew(['email' => $email]);
        $user->fill(['name' => $user->name ?: $this->option('name'), 'password' => $password, 'status' => 'active']);
        $user->forceFill(['role' => User::ROLE_SUPERADMIN, 'coach_type' => null])->save();

        $this->info("Superadmin ready: {$email}");

        return self::SUCCESS;
    }
}
