import { useState } from 'react';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { api, errorMessage } from '../../api/client';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, EmptyState, ErrorState, Loader, Pagination, StatusBadge } from '../../components/ui';
import { dateTime, money } from '../../utils/format';

const EVENT_LABELS = {
  'order.created': 'Checkout started',
  'payment.verified': 'Paid (verified in app/panel)',
  'webhook.payment.captured': 'Paid (Razorpay webhook)',
  'webhook.order.paid': 'Paid (Razorpay webhook)',
  'webhook.payment.failed': 'Payment failed',
  'manual.assigned': 'Assigned by admin',
  'subscription.cancelled': 'Cancelled',
};

export default function Payments() {
  usePageTitle('Payments', 'Razorpay events and manual assignments, newest first.');
  const [filters, setFilters] = useState({ search: '', status: '', page: 1 });

  const { data, isLoading, error, refetch, isFetching } = useQuery({
    queryKey: ['admin-payments', filters],
    queryFn: () => api.get('/admin/payments', { params: { ...filters, per_page: 20 } }).then((r) => r.data),
    placeholderData: keepPreviousData,
  });

  const setFilter = (key) => (e) => setFilters({ ...filters, [key]: e.target.value, page: 1 });

  return (
    <Card title="Payment Log" subtitle={data ? `${data.meta.total} events` : ''}>
      <div className="row g-2 mb-3">
        <div className="col-md-6">
          <input className="form-control" placeholder="Search coach, order ID or payment ID" value={filters.search} onChange={setFilter('search')} />
        </div>
        <div className="col-md-3">
          <select className="form-select" value={filters.status} onChange={setFilter('status')}>
            <option value="">Any status</option>
            <option value="captured">Captured</option>
            <option value="created">Created</option>
            <option value="failed">Failed</option>
            <option value="assigned">Assigned</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>
      </div>
      {isLoading ? (
        <Loader />
      ) : error ? (
        <ErrorState message={errorMessage(error)} onRetry={refetch} />
      ) : data.data.length === 0 ? (
        <EmptyState icon="receipt" message="No payment events yet." />
      ) : (
        <div className={`table-responsive ${isFetching ? 'opacity-75' : ''}`}>
          <table className="table table-striped mb-0">
            <thead>
              <tr>
                <th>When</th>
                <th>Coach</th>
                <th>Event</th>
                <th>Plan</th>
                <th>Amount</th>
                <th>Razorpay IDs</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {data.data.map((p) => (
                <tr key={p.id}>
                  <td className="small text-nowrap">{dateTime(p.created_at)}</td>
                  <td>
                    {p.user?.name || '-'}
                    <div className="small text-muted">{p.user?.email}</div>
                  </td>
                  <td>{EVENT_LABELS[p.event] || p.event}</td>
                  <td>{p.plan_name || '-'}</td>
                  <td>{money(p.amount)}</td>
                  <td className="small text-muted">
                    {p.razorpay_order_id || '-'}
                    {p.razorpay_payment_id && <div>{p.razorpay_payment_id}</div>}
                  </td>
                  <td><StatusBadge status={p.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <Pagination meta={data?.meta} onPage={(page) => setFilters({ ...filters, page })} />
    </Card>
  );
}
