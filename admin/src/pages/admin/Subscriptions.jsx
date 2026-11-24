import { useState } from 'react';
import { keepPreviousData, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, useSearchParams } from 'react-router-dom';
import { api, errorMessage } from '../../api/client';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, ConfirmModal, EmptyState, ErrorState, Loader, Pagination, StatusBadge, TierBadge } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';
import { COACH_TYPES, date, money, TIERS, titleCase } from '../../utils/format';

export default function Subscriptions() {
  usePageTitle('Subscriptions', 'Every plan purchased online or assigned by an admin.');
  const [params] = useSearchParams();
  const queryClient = useQueryClient();
  const notify = useToast();
  const [filters, setFilters] = useState({
    status: params.get('status') || '',
    coach_type: '',
    tier: '',
    source: '',
    search: '',
    page: 1,
  });
  const [cancelling, setCancelling] = useState(null);
  const [busy, setBusy] = useState(false);

  const { data, isLoading, error, refetch, isFetching } = useQuery({
    queryKey: ['admin-subscriptions', filters],
    queryFn: () => api.get('/admin/subscriptions', { params: { ...filters, per_page: 15 } }).then((r) => r.data),
    placeholderData: keepPreviousData,
  });

  const setFilter = (key) => (e) => setFilters({ ...filters, [key]: e.target.value, page: 1 });

  const cancel = async () => {
    setBusy(true);
    try {
      await api.post(`/admin/subscriptions/${cancelling.id}/cancel`);
      notify('Subscription cancelled');
      queryClient.invalidateQueries({ queryKey: ['admin-subscriptions'] });
      setCancelling(null);
    } catch (err) {
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Card title="Subscriptions" subtitle={data ? `${data.meta.total} records` : ''}>
      <div className="row g-2 mb-3">
        <div className="col-md-3">
          <input className="form-control" placeholder="Search coach" value={filters.search} onChange={setFilter('search')} />
        </div>
        <div className="col-md-2 col-6">
          <select className="form-select" value={filters.status} onChange={setFilter('status')}>
            <option value="">Any status</option>
            <option value="current">Current</option>
            <option value="pending">Pending payment</option>
            <option value="expired">Expired</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>
        <div className="col-md-2 col-6">
          <select className="form-select" value={filters.coach_type} onChange={setFilter('coach_type')}>
            <option value="">All types</option>
            {COACH_TYPES.map((t) => <option key={t} value={t}>{titleCase(t)}</option>)}
          </select>
        </div>
        <div className="col-md-2 col-6">
          <select className="form-select" value={filters.tier} onChange={setFilter('tier')}>
            <option value="">All tiers</option>
            {TIERS.map((t) => <option key={t} value={t}>{titleCase(t)}</option>)}
          </select>
        </div>
        <div className="col-md-3 col-6">
          <select className="form-select" value={filters.source} onChange={setFilter('source')}>
            <option value="">Any source</option>
            <option value="panel">Web panel</option>
            <option value="app">Mobile app</option>
            <option value="manual">Assigned by admin</option>
          </select>
        </div>
      </div>

      {isLoading ? (
        <Loader />
      ) : error ? (
        <ErrorState message={errorMessage(error)} onRetry={refetch} />
      ) : data.data.length === 0 ? (
        <EmptyState icon="card" message="No subscriptions match these filters." />
      ) : (
        <div className={`table-responsive ${isFetching ? 'opacity-75' : ''}`}>
          <table className="table table-striped mb-0">
            <thead>
              <tr>
                <th>Coach</th>
                <th>Plan</th>
                <th>Period</th>
                <th>Amount</th>
                <th>Source</th>
                <th>Status</th>
                <th className="text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
              {data.data.map((s) => (
                <tr key={s.id}>
                  <td>
                    <Link to={`/coaches/${s.user?.id}`}>{s.user?.name}</Link>
                    <div className="small text-muted">{s.user?.email}</div>
                  </td>
                  <td>
                    {s.plan?.name} <TierBadge tier={s.plan?.tier} />
                  </td>
                  <td className="small">
                    {s.starts_at ? `${date(s.starts_at)} - ${date(s.ends_at)}` : '-'}
                    {s.is_current && <div className="text-muted">{s.days_left} days left</div>}
                  </td>
                  <td>
                    {money(s.amount)}
                    {s.razorpay_payment_id && <div className="small text-muted">{s.razorpay_payment_id}</div>}
                  </td>
                  <td>{titleCase(s.source)}</td>
                  <td>
                    <StatusBadge status={s.status} />
                    {s.notes && <div className="small text-muted">{s.notes}</div>}
                  </td>
                  <td className="text-end">
                    {(s.status === 'active' || s.status === 'pending') && (
                      <button type="button" className="btn btn-sm btn-soft-danger" onClick={() => setCancelling(s)}>Cancel</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <Pagination meta={data?.meta} onPage={(page) => setFilters({ ...filters, page })} />

      <ConfirmModal
        show={cancelling !== null}
        title="Cancel subscription?"
        message={`Cancel ${cancelling?.plan?.name} for ${cancelling?.user?.name}? They lose plan access immediately. Refunds must be issued from the Razorpay dashboard.`}
        confirmLabel="Cancel Subscription"
        busy={busy}
        onConfirm={cancel}
        onClose={() => setCancelling(null)}
      />
    </Card>
  );
}
