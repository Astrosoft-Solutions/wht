<?php

namespace Tests\Feature;

use App\Models\MasterHabit;
use App\Models\Plan;
use App\Models\User;
use Database\Seeders\ProductionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class DeployHookTest extends TestCase
{
    use RefreshDatabase;

    public function test_hook_is_hidden_without_a_configured_token(): void
    {
        config(['services.deploy.token' => null]);

        $this->postJson('/api/deploy/hook')->assertNotFound();
        $this->withToken('anything')->postJson('/api/deploy/hook')->assertNotFound();
    }

    public function test_hook_rejects_a_wrong_token(): void
    {
        config(['services.deploy.token' => 'secret-token']);

        $this->withToken('wrong')->postJson('/api/deploy/hook')->assertNotFound();
    }

    public function test_hook_runs_the_release_commands(): void
    {
        config(['services.deploy.token' => 'secret-token']);
        Plan::factory()->create();

        // The real commands would write cache files into bootstrap/cache during the test run.
        Artisan::shouldReceive('call')->andReturn(0);
        Artisan::shouldReceive('output')->andReturn('done');

        $commands = collect($this->withToken('secret-token')->postJson('/api/deploy/hook')
            ->assertOk()
            ->assertJsonPath('ok', true)
            ->json('steps'))->pluck('command')->all();

        $this->assertSame('extract-vendor.zip', $commands[0]);
        $this->assertSame('optimize:clear', $commands[1]);
        $this->assertSame('migrate', $commands[2]);
        $this->assertNotContains('db:seed', $commands);
        $this->assertSame('optimize', end($commands));
    }

    public function test_hook_reports_a_failed_command(): void
    {
        config(['services.deploy.token' => 'secret-token']);
        Plan::factory()->create();

        Artisan::shouldReceive('call')->with('optimize:clear', [])->andReturn(0);
        Artisan::shouldReceive('call')->with('migrate', ['--force' => true])->andReturn(1);
        Artisan::shouldReceive('output')->andReturn('SQLSTATE[HY000] [1045] Access denied');

        $this->withToken('secret-token')->postJson('/api/deploy/hook')
            ->assertStatus(500)
            ->assertJsonPath('ok', false)
            ->assertJsonPath('steps.2.command', 'migrate');
    }

    public function test_production_seeder_creates_only_reference_data_and_the_superadmin(): void
    {
        config(['services.superadmin.email' => 'owner@example.com', 'services.superadmin.password' => 'S3cure-pass']);

        $this->seed(ProductionSeeder::class);
        $this->seed(ProductionSeeder::class);

        $this->assertSame(9, Plan::count());
        $this->assertGreaterThan(0, MasterHabit::count());
        $this->assertSame(1, User::count());
        $this->assertTrue(User::first()->isSuperadmin());
    }

    public function test_production_seeder_requires_superadmin_credentials(): void
    {
        config(['services.superadmin.email' => 'owner@example.com', 'services.superadmin.password' => null]);

        $this->expectException(\RuntimeException::class);
        $this->seed(ProductionSeeder::class);
    }
}
