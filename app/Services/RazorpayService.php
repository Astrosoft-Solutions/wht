<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Thin client for the parts of the Razorpay API this app uses: orders and signature checks.
 */
class RazorpayService
{
    private const API = 'https://api.razorpay.com/v1';

    public function isConfigured(): bool
    {
        return filled(config('services.razorpay.key_id')) && filled(config('services.razorpay.key_secret'));
    }

    public function keyId(): ?string
    {
        return config('services.razorpay.key_id');
    }

    /**
     * @param  array<string, string|int>  $notes
     * @return array{id: string, amount: int, currency: string, receipt: string, status: string}
     */
    public function createOrder(int $amountPaise, string $currency, string $receipt, array $notes = []): array
    {
        if (! $this->isConfigured()) {
            throw new RuntimeException('Online payments are not configured yet. Please contact support.');
        }

        $response = Http::withBasicAuth(config('services.razorpay.key_id'), config('services.razorpay.key_secret'))
            ->acceptJson()
            ->timeout(15)
            ->post(self::API.'/orders', [
                'amount' => $amountPaise,
                'currency' => $currency,
                'receipt' => $receipt,
                'notes' => $notes,
            ]);

        if (! $response->successful() || ! $response->json('id')) {
            throw new RuntimeException('Could not start the payment: '.($response->json('error.description') ?? 'Razorpay error'));
        }

        return $response->json();
    }

    /**
     * Checks the signature Razorpay Checkout returns to the client after a successful payment.
     */
    public function verifyPaymentSignature(string $orderId, string $paymentId, string $signature): bool
    {
        $secret = (string) config('services.razorpay.key_secret');
        if ($secret === '') {
            return false;
        }

        return hash_equals(hash_hmac('sha256', $orderId.'|'.$paymentId, $secret), $signature);
    }

    public function verifyWebhookSignature(string $rawBody, ?string $signature): bool
    {
        $secret = (string) config('services.razorpay.webhook_secret');
        if ($secret === '' || ! $signature) {
            return false;
        }

        return hash_equals(hash_hmac('sha256', $rawBody, $secret), $signature);
    }
}
