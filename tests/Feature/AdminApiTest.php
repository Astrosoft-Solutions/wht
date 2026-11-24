<?php

namespace Tests\Feature;

use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Sanctum::actingAs(User::factory()->superadmin()->create());
    }

    public function test_dashboard_reports_coaches_subscriptions_and_revenue(): void
    {
        $plan = Plan::factory()->tier('coach', 'gold')->create();
        Subscription::factory()->for($plan)->for(User::factory()->coach())->create([
            'source' => 'panel', 'razorpay_payment_id' => 'pay_1', 'amount_paise' => 399900,
        ]);
        User::factory()->coach('guide')->create();

        $this->getJson('/api/v1/admin/dashboard')
            ->assertOk()
            ->assertJsonPath('coaches.total', 2)
            ->assertJsonPath('coaches.by_type.guide', 1)
            ->assertJsonPath('subscriptions.active', 1)
            ->assertJsonPath('subscriptions.by_tier.gold', 1)
            ->assertJsonPath('revenue.this_month', 3999);
    }

    public function test_coach_crud_and_manual_plan_assignment(): void
    {
        $plan = Plan::factory()->tier('consultant', 'silver', 30)->create();

        $id = $this->postJson('/api/v1/admin/coaches', [
            'name' => 'Anita',
            'email' => 'anita@example.com',
            'password' => 'password123',
            'coach_type' => 'consultant',
        ])->assertCreated()->assertJsonPath('data.coach_type', 'consultant')->json('data.id');

        $this->postJson("/api/v1/admin/coaches/{$id}/assign-plan", ['plan_id' => $plan->id, 'amount' => 2999])
            ->assertCreated()
            ->assertJsonPath('data.status', 'active')
            ->assertJsonPath('data.amount', 2999);

        $this->getJson('/api/v1/admin/coaches?plan=with')
            ->assertOk()
            ->assertJsonPath('data.0.subscription.plan.tier', 'silver');

        $this->putJson("/api/v1/admin/coaches/{$id}", ['status' => 'inactive'])
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');

        $this->deleteJson("/api/v1/admin/coaches/{$id}")->assertNoContent();
    }

    public function test_admin_cannot_edit_superadmin_through_coach_endpoints(): void
    {
        $other = User::factory()->superadmin()->create();

        $this->putJson("/api/v1/admin/coaches/{$other->id}", ['name' => 'x'])->assertNotFound();
    }

    public function test_plan_crud_and_unique_tier_per_type(): void
    {
        $id = $this->postJson('/api/v1/admin/plans', [
            'coach_type' => 'guide', 'tier' => 'gold', 'name' => 'Guide Gold', 'price' => 1999, 'max_customers' => null,
            'features' => ['Unlimited customers'],
        ])->assertCreated()->assertJsonPath('data.price_paise', 199900)->json('data.id');

        $this->postJson('/api/v1/admin/plans', [
            'coach_type' => 'guide', 'tier' => 'gold', 'name' => 'Duplicate', 'price' => 10,
        ])->assertUnprocessable()->assertJsonValidationErrors('tier');

        $this->putJson("/api/v1/admin/plans/{$id}", ['price' => 2499, 'is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.price', 2499)
            ->assertJsonPath('data.is_active', false);

        Subscription::factory()->create(['plan_id' => $id]);
        $this->deleteJson("/api/v1/admin/plans/{$id}")->assertUnprocessable();
    }

    public function test_gallery_upload_youtube_and_delete(): void
    {
        Storage::fake('public');

        $image = $this->post('/api/v1/admin/gallery', [
            'type' => 'image',
            'title' => 'Healthy breakfast',
            'file' => UploadedFile::fake()->image('food.jpg'),
        ], ['Accept' => 'application/json'])->assertCreated()->json('data');
        $this->assertNotNull($image['file_url']);

        $this->postJson('/api/v1/admin/gallery', [
            'type' => 'video', 'title' => 'Yoga', 'video_url' => 'https://www.youtube.com/watch?v=abcdefghijk',
        ])->assertCreated()->assertJsonPath('data.youtube_id', 'abcdefghijk');

        $this->postJson('/api/v1/admin/gallery', ['type' => 'video', 'title' => 'Missing source'])
            ->assertUnprocessable();

        $this->postJson('/api/v1/admin/gallery', [
            'type' => 'video', 'title' => 'Not YouTube', 'video_url' => 'https://vimeo.com/123',
        ])->assertUnprocessable()->assertJsonValidationErrors('video_url');

        $this->post("/api/v1/admin/gallery/{$image['id']}", ['_method' => 'PUT', 'is_published' => '0'], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('data.is_published', false);

        $this->deleteJson("/api/v1/admin/gallery/{$image['id']}")->assertNoContent();
        $this->assertCount(0, Storage::disk('public')->allFiles('gallery/images'));
    }

    public function test_master_habits_announcements_and_settings(): void
    {
        $habitId = $this->postJson('/api/v1/admin/master-habits', ['name' => 'Water', 'start_time' => '08:00', 'end_time' => '09:00'])
            ->assertCreated()->json('data.id');
        $this->putJson("/api/v1/admin/master-habits/{$habitId}", ['is_active' => false])->assertOk()->assertJsonPath('data.is_active', false);

        $this->postJson('/api/v1/admin/announcements', ['title' => 'Hello', 'body' => 'World', 'audience' => 'coach'])
            ->assertCreated()
            ->assertJsonPath('data.audience', 'coach');

        $this->putJson('/api/v1/admin/settings', ['reminder_lead_minutes' => 20, 'reminders_default_on' => false])
            ->assertOk()
            ->assertJsonPath('data.reminder_lead_minutes', 20)
            ->assertJsonPath('data.reminders_default_on', false);
    }
}
