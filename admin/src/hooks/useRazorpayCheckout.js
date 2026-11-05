import { useCallback, useState } from 'react';
import { api, errorMessage } from '../api/client';

const SCRIPT_URL = 'https://checkout.razorpay.com/v1/checkout.js';

function loadScript() {
  if (window.Razorpay) return Promise.resolve();
  return new Promise((resolve, reject) => {
    const existing = document.querySelector(`script[src="${SCRIPT_URL}"]`);
    const script = existing || document.createElement('script');
    script.src = SCRIPT_URL;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error('Could not load Razorpay. Check your internet connection.'));
    if (!existing) document.body.appendChild(script);
  });
}

/**
 * Creates an order on the server, opens Razorpay Checkout, then verifies the payment.
 * Resolves with the server's success message, or null when the user closes the checkout.
 */
export function useRazorpayCheckout() {
  const [busyPlanId, setBusyPlanId] = useState(null);

  const pay = useCallback(async (plan) => {
    setBusyPlanId(plan.id);
    try {
      await loadScript();
      const { data: order } = await api.post('/subscriptions/checkout', { plan_id: plan.id, source: 'panel' });

      return await new Promise((resolve, reject) => {
        const checkout = new window.Razorpay({
          key: order.key_id,
          amount: order.amount,
          currency: order.currency,
          order_id: order.order_id,
          name: order.name,
          description: order.description,
          prefill: order.prefill,
          theme: { color: '#1B5E20' },
          handler: async (response) => {
            try {
              const { data } = await api.post('/subscriptions/verify', response);
              resolve(data.message);
            } catch (err) {
              reject(new Error(errorMessage(err)));
            }
          },
          modal: { ondismiss: () => resolve(null) },
        });
        checkout.on('payment.failed', (response) => reject(new Error(response.error?.description || 'Payment failed.')));
        checkout.open();
      });
    } catch (err) {
      throw new Error(err instanceof Error && !err.response ? err.message : errorMessage(err));
    } finally {
      setBusyPlanId(null);
    }
  }, []);

  return { pay, busyPlanId };
}
