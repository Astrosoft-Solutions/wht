import { errorMessage } from '../../api/client';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, EmptyState, ErrorState, Loader, StatusBadge, TierBadge } from '../../components/ui';
import { date, dateTime, money, titleCase } from '../../utils/format';
import { useSubscription } from './useSubscription';

const EVENT_LABELS = {
  'payment.verified': 'Online payment',
  'webhook.payment.captured': 'Online payment',
  'webhook.order.paid': 'Online payment',
  'manual.assigned': 'Assigned by admin',
};

export default function Billing() {
  usePageTitle('Billing', 'Your plans and payments.');
  const { data, isLoading, error, refetch } = useSubscription();

  if (isLoading) return <Card><Loader /></Card>;
  if (error) return <ErrorState message={errorMessage(error)} onRetry={refetch} />;

  return (
    <>
      <Card title="Plan History" bodyClassName="p-0">
        {data.history.length === 0 ? (
          <EmptyState icon="crown" message="You haven't subscribed to a plan yet." />
        ) : (
          <div className="table-responsive">
            <table className="table table-striped mb-0">
              <thead>
                <tr>
                  <th>Plan</th>
                  <th>Period</th>
                  <th>Amount</th>
                  <th>Paid via</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {data.history.map((s) => (
                  <tr key={s.id}>
                    <td>{s.plan?.name} <TierBadge tier={s.plan?.tier} /></td>
                    <td className="small">{date(s.starts_at)} - {date(s.ends_at)}</td>
                    <td>{money(s.amount)}</td>
                    <td>{s.source === 'manual' ? 'Admin' : titleCase(s.source)}</td>
                    <td><StatusBadge status={s.is_current ? 'active' : s.status} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <Card title="Payments" bodyClassName="p-0">
        {data.payments.length === 0 ? (
          <EmptyState icon="receipt" message="No payments yet." />
        ) : (
          <div className="table-responsive">
            <table className="table table-striped mb-0">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Description</th>
                  <th>Plan</th>
                  <th>Amount</th>
                  <th>Payment ID</th>
                </tr>
              </thead>
              <tbody>
                {data.payments.map((p) => (
                  <tr key={p.id}>
                    <td className="small">{dateTime(p.created_at)}</td>
                    <td>{EVENT_LABELS[p.event] || p.event}</td>
                    <td>{p.plan_name}</td>
                    <td>{money(p.amount)}</td>
                    <td className="small text-muted">{p.razorpay_payment_id || '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </>
  );
}
