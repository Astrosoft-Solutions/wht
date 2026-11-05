<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CustomerTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->withPlan()->create();
        Sanctum::actingAs($this->user);
    }

    public function test_create_customer_generates_code_and_baseline_measurement(): void
    {
        $this->postJson('/api/v1/customers', [
            'name' => 'Lakshmi Priya',
            'height_cm' => 165,
            'weight' => 72,
            'fat_percent' => 32,
            'chest' => 98,
            'waist' => 86,
        ])
            ->assertCreated()
            ->assertJsonPath('data.customer_code', 'CUST001')
            ->assertJsonPath('data.baseline_measurement.weight', 72)
            ->assertJsonPath('data.baseline_measurement.bmi', 26.4);

        $this->postJson('/api/v1/customers', ['name' => 'Second'])
            ->assertCreated()
            ->assertJsonPath('data.customer_code', 'CUST002')
            ->assertJsonPath('data.baseline_measurement', null);
    }

    public function test_list_supports_search(): void
    {
        Customer::factory()->for($this->user)->create(['name' => 'Ramesh Kumar']);
        Customer::factory()->for($this->user)->create(['name' => 'Priya S']);
        Customer::factory()->create(['name' => 'Ramesh Other User']);

        $this->getJson('/api/v1/customers?search=Ramesh')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Ramesh Kumar');
    }

    public function test_update_customer_and_notes(): void
    {
        $customer = Customer::factory()->for($this->user)->create();

        $this->putJson("/api/v1/customers/{$customer->id}", ['status' => 'inactive', 'weight' => 70])
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive')
            ->assertJsonPath('data.baseline_measurement.weight', 70);

        $this->patchJson("/api/v1/customers/{$customer->id}/notes", [
            'health_condition_before' => 'Overweight',
            'remarks' => 'Improved',
        ])->assertOk()->assertJsonPath('data.remarks', 'Improved');
    }

    public function test_cannot_access_other_users_customer(): void
    {
        $other = Customer::factory()->create();

        $this->getJson("/api/v1/customers/{$other->id}")->assertForbidden();
        $this->getJson("/api/v1/customers/{$other->id}/measurements")->assertForbidden();
    }

    public function test_programmes_and_measurements(): void
    {
        $customer = Customer::factory()->for($this->user)->create(['height_cm' => 174]);

        $programmeId = $this->postJson("/api/v1/customers/{$customer->id}/programmes", [
            'name' => 'Programme 1',
            'goal' => 'Weight Loss',
            'total_weeks' => 12,
            'weeks_completed' => 10,
        ])->assertCreated()->assertJsonPath('data.weeks_remaining', 2)->json('data.id');

        $this->postJson("/api/v1/customers/{$customer->id}/programmes", [
            'name' => 'Bad', 'total_weeks' => 4, 'weeks_completed' => 6,
        ])->assertUnprocessable();

        $this->postJson("/api/v1/customers/{$customer->id}/measurements", [
            'programme_id' => $programmeId,
            'recorded_on' => '2026-11-01',
            'weight' => 80,
            'fat_percent' => 30.5,
            'total_points' => 10,
        ])->assertCreated()->assertJsonPath('data.bmi', 26.4);

        $this->getJson("/api/v1/customers/{$customer->id}/measurements?programme_id={$programmeId}")
            ->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_photo_upload_replaces_same_type(): void
    {
        Storage::fake('public');
        $customer = Customer::factory()->for($this->user)->create();

        $first = $this->post("/api/v1/customers/{$customer->id}/photos", [
            'type' => 'before',
            'photo' => UploadedFile::fake()->image('before.jpg'),
        ], ['Accept' => 'application/json'])->assertCreated()->json('data');

        $this->post("/api/v1/customers/{$customer->id}/photos", [
            'type' => 'before',
            'photo' => UploadedFile::fake()->image('before2.jpg'),
        ], ['Accept' => 'application/json'])->assertCreated();

        $this->assertDatabaseCount('customer_photos', 1);
        $this->assertDatabaseMissing('customer_photos', ['id' => $first['id']]);
    }
}
