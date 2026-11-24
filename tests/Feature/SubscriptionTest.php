<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SubscriptionTest extends TestCase
{
    use RefreshDatabase;

    private Plan $gold;
    private Plan $bronze;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'services.razorpay.key_id' => 'rzp_test_key',
            'services.razorpay.key_secret' => 'test_secret',
            'services.razorpay.webhook_secret' => 'webhook_secret',
        ]);

        $this->gold = Plan::factory()->tier('coach', 'gold', null)->create(['price_paise' => 399900]);
        $this->bronze = Plan::factory()->tier('coach', 'bronze', 1)->create(['price_paise' => 99900]);
    }

    private function fakeOrder(string $orderId = 'order_123'): void
    {
        Http::fake([
            'api.razorpay.com/v1/orders' => Http::response([
                'id' => $orderId, 'amount' => 399900, 'currency' => 'INR', 'receipt' => 'r', 'status' => 'created',
            ]),
        ]);
    }

    public function test_plans_list_defaults_to_the_coachs_type(): void
    {
        Plan::factory()->tier('guide', 'gold')->create();
        Sanctum::actingAs(User::factory()->coach('coach')->create());

        $this->getJson('/api/v1/plans')->assertOk()->assertJsonCount(2, 'data');
        $this->getJson('/api/v1/plans?coach_type=all')->assertOk()->assertJsonCount(3, 'data');
    }

    public function test_checkout_creates_razorpay_order_and_pending_subscription(): void
    {
        $this->fakeOrder();
        $coach = User::factory()->coach()->create();
        Sanctum::actingAs($coach);

        $this->postJson('/api/v1/subscriptions/checkout', ['plan_id' => $this->gold->id, 'source' => 'panel'])
            ->assertCreated()
            ->assertJsonPath('order_id', 'order_123')
            ->assertJsonPath('key_id', 'rzp_test_key')
            ->assertJsonPath('amount', 399900);

        Http::assertSent(fn ($request) => $request->url() === 'https://api.razorpay.com/v1/orders' && $request['amount'] === 399900);
        $this->assertDatabaseHas('subscriptions', ['user_id' => $coach->id, 'status' => 'pending', 'razorpay_order_id' => 'order_123']);
    }

    public function test_checkout_rejects_plan_for_another_coach_type(): void
    {
        $this->fakeOrder();
        $guidePlan = Plan::factory()->tier('guide', 'gold')->create();
        Sanctum::actingAs(User::factory()->coach('coach')->create());

        $this->postJson('/api/v1/subscriptions/checkout', ['plan_id' => $guidePlan->id])->assertUnprocessable();
    }

    public function test_checkout_without_razorpay_keys_returns_503(): void
    {
        config(['services.razorpay.key_id' => null]);
        Sanctum::actingAs(User::factory()->coach()->create());

        $this->postJson('/api/v1/subscriptions/checkout', ['plan_id' => $this->gold->id])->assertStatus(503);
    }

    public function test_verify_with_valid_signature_activates_plan(): void
    {
        $this->fakeOrder();
        $coach = User::factory()->coach()->create();
        Sanctum::actingAs($coach);
        $this->postJson('/api/v1/subscriptions/checkout', ['plan_id' => $this->gold->id])->assertCreated();

        $signature = hash_hmac('sha256', 'order_123|pay_1', 'test_secret');

        $this->postJson('/api/v1/subscriptions/verify', [
            'razorpay_order_id' => 'order_123',
            'razorpay_payment_id' => 'pay_1',
            'razorpay_signature' => $signature,
        ])->assertOk()->assertJsonPath('subscription.status', 'active')->assertJsonPath('subscription.is_current', true);

        $this->getJson('/api/v1/me')->assertJsonPath('data.subscription.plan.tier', 'gold');
    }

    public function test_verify_with_bad_signature_is_rejected(): void
    {
        $this->fakeOrder();
        Sanctum::actingAs(User::factory()->coach()->create());
        $this->postJson('/api/v1/subscriptions/checkout', ['plan_id' => $this->gold->id])->assertCreated();

        $this->postJson('/api/v1/subscriptions/verify', [
            'razorpay_order_id' => 'order_123',
            'razorpay_payment_id' => 'pay_1',
            'razorpay_signature' => 'forged',
        ])->assertUnprocessable();

        $this->assertDatabaseHas('subscriptions', ['razorpay_order_id' => 'order_123', 'status' => 'pending']);
    }

    public function test_webhook_activates_subscription_once(): void
    {
        $coach = User::factory()->coach()->create();
        $subscription = $coach->subscriptions()->create([
            'plan_id' => $this->gold->id, 'status' => 'pending', 'amount_paise' => 399900,
            'currency' => 'INR', 'source' => 'app', 'razorpay_order_id' => 'order_wh',
        ]);

        $body = json_encode([
            'event' => 'payment.captured',
            'payload' => ['payment' => ['entity' => ['id' => 'pay_wh', 'order_id' => 'order_wh', 'amount' => 399900]]],
        ]);
        $headers = ['X-Razorpay-Signature' => hash_hmac('sha256', $body, 'webhook_secret'), 'Content-Type' => 'application/json'];

        $this->call('POST', '/api/v1/razorpay/webhook', [], [], [], $this->transformHeadersToServerVars($headers), $body)->assertOk();
        $endsAt = $subscription->refresh()->ends_at;
        $this->assertSame('active', $subscription->status);

        $this->call('POST', '/api/v1/razorpay/webhook', [], [], [], $this->transformHeadersToServerVars($headers), $body)->assertOk();
        $this->assertEquals($endsAt, $subscription->refresh()->ends_at);
    }

    public function test_webhook_with_bad_signature_is_rejected(): void
    {
        $this->postJson('/api/v1/razorpay/webhook', ['event' => 'payment.captured'], ['X-Razorpay-Signature' => 'nope'])
            ->assertStatus(400);
    }

    public function test_renewing_same_plan_extends_and_switching_plan_replaces(): void
    {
        $coach = User::factory()->coach()->create();
        $service = app(\App\Services\SubscriptionService::class);

        $first = $service->assignManually($coach, $this->gold);
        $renewal = $service->assignManually($coach, $this->gold);
        $this->assertTrue($renewal->starts_at->equalTo($first->ends_at));

        $switch = $service->assignManually($coach, $this->bronze);
        $this->assertTrue($switch->isCurrent());
        $this->assertSame('cancelled', $first->refresh()->status);
        $this->assertSame('cancelled', $renewal->refresh()->status);
    }

    public function test_customer_creation_is_limited_by_plan(): void
    {
        $coach = User::factory()->coach()->create();
        Sanctum::actingAs($coach);

        $this->postJson('/api/v1/customers', ['name' => 'No Plan'])
            ->assertForbidden()
            ->assertJsonPath('code', 'plan_limit');

        app(\App\Services\SubscriptionService::class)->assignManually($coach, $this->bronze);
        $this->postJson('/api/v1/customers', ['name' => 'First'])->assertCreated();
        $this->postJson('/api/v1/customers', ['name' => 'Second'])->assertForbidden();
        $this->assertSame(1, Customer::count());
    }

    public function test_expire_command_marks_overdue_subscriptions(): void
    {
        $subscription = Subscription::factory()->create(['starts_at' => now()->subDays(40), 'ends_at' => now()->subDays(10)]);

        $this->artisan('subscriptions:expire')->assertSuccessful();

        $this->assertSame('expired', $subscription->refresh()->status);
    }
}
