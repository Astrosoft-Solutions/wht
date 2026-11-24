import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage } from '../../api/client';
import { useAuth } from '../../auth/AuthContext';
import Icon from '../../components/Icon';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, EmptyState, ErrorState, Loader, TierBadge } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';
import { useRazorpayCheckout } from '../../hooks/useRazorpayCheckout';
import { date, money, titleCase } from '../../utils/format';
import { useSubscription } from './useSubscription';

export default function ChoosePlan() {
  const { user, refreshUser } = useAuth();
  usePageTitle('Choose Your Plan', `Plans for ${titleCase(user?.coach_type)}s. Pay securely with Razorpay.`);
  const queryClient = useQueryClient();
  const notify = useToast();
  const subscription = useSubscription();
  const { pay, busyPlanId } = useRazorpayCheckout();
  const plans = useQuery({
    queryKey: ['coach-plans'],
    queryFn: () => api.get('/plans').then((r) => r.data.data),
  });

  if (plans.isLoading || subscription.isLoading) return <Card><Loader /></Card>;
  if (plans.error) return <ErrorState message={errorMessage(plans.error)} onRetry={plans.refetch} />;

  const current = subscription.data?.current;
  const paymentsEnabled = subscription.data?.payments_enabled;

  const buy = async (plan) => {
    try {
      const message = await pay(plan);
      if (message) {
        notify(message);
        queryClient.invalidateQueries({ queryKey: ['coach-subscription'] });
        refreshUser();
      }
    } catch (err) {
      notify(err.message, 'error');
    }
  };

  const actionLabel = (plan) => {
    if (!current) return 'Subscribe';
    if (current.plan.id === plan.id) return 'Renew';
    return 'Switch to this plan';
  };

  return (
    <>
      {!paymentsEnabled && (
        <div className="alert alert-warning">
          Online payments are not set up yet. Please contact the administrator to activate a plan.
        </div>
      )}
      {current && (
        <div className="alert alert-light border">
          Your <strong>{current.plan.name}</strong> plan is active until <strong>{date(current.ends_at)}</strong>.
          Renewing adds another period after that date; switching to another plan starts it immediately and replaces the current one.
        </div>
      )}
      {plans.data.length === 0 ? (
        <Card><EmptyState icon="crown" message="No plans are available right now." /></Card>
      ) : (
        <div className="row g-3">
          {plans.data.map((plan) => {
            const isCurrent = current?.plan.id === plan.id;
            return (
              <div key={plan.id} className="col-md-6 col-xl-4">
                <div className={`card pricing-card h-100 ${isCurrent ? 'is-current' : ''}`}>
                  <div className="card-body d-flex flex-column">
                    <div className="d-flex justify-content-between align-items-center mb-2">
                      <TierBadge tier={plan.tier} />
                      {isCurrent && <span className="badge bg-primary">Current plan</span>}
                    </div>
                    <h4 className="mb-1">{plan.name}</h4>
                    {plan.description && <p className="text-muted small mb-2">{plan.description}</p>}
                    <div className="mb-3">
                      <span className="price text-primary">{money(plan.price)}</span>
                      <span className="text-muted"> / {plan.duration_days} days</span>
                    </div>
                    <ul className="list-unstyled flex-grow-1">
                      <li className="mb-2 d-flex gap-2">
                        <Icon name="users" size={16} className="text-success mt-1" />
                        <span>{plan.max_customers ? `Up to ${plan.max_customers} customers` : 'Unlimited customers'}</span>
                      </li>
                      {plan.features.map((f) => (
                        <li key={f} className="mb-2 d-flex gap-2">
                          <Icon name="check" size={16} className="text-success mt-1 flex-shrink-0" />
                          <span>{f}</span>
                        </li>
                      ))}
                    </ul>
                    <button
                      type="button"
                      className={`btn ${isCurrent ? 'btn-outline-primary' : 'btn-primary'} w-100`}
                      disabled={!paymentsEnabled || busyPlanId !== null}
                      onClick={() => buy(plan)}
                    >
                      {busyPlanId === plan.id && <span className="spinner-border spinner-border-sm me-2" />}
                      {actionLabel(plan)} - {money(plan.price)}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </>
  );
}
