import { useState } from 'react';
import { keepPreviousData, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { api, errorMessage } from '../../api/client';
import Icon from '../../components/Icon';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, ConfirmModal, EmptyState, ErrorState, Loader, Pagination, StatusBadge, TierBadge } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';
import { COACH_TYPES, date, titleCase } from '../../utils/format';
import { AssignPlanModal, CoachFormModal } from './coachModals';

export default function Coaches() {
  usePageTitle('Coaches', 'Consultants, coaches and guides using the app.');
  const queryClient = useQueryClient();
  const notify = useToast();
  const [filters, setFilters] = useState({ search: '', coach_type: '', status: '', plan: '', page: 1 });
  const [editing, setEditing] = useState(null);
  const [assigning, setAssigning] = useState(null);
  const [deleting, setDeleting] = useState(null);
  const [busy, setBusy] = useState(false);

  const { data, isLoading, error, refetch, isFetching } = useQuery({
    queryKey: ['admin-coaches', filters],
    queryFn: () => api.get('/admin/coaches', { params: { ...filters, per_page: 15 } }).then((r) => r.data),
    placeholderData: keepPreviousData,
  });

  const setFilter = (key) => (e) => setFilters({ ...filters, [key]: e.target.value, page: 1 });

  const remove = async () => {
    setBusy(true);
    try {
      await api.delete(`/admin/coaches/${deleting.id}`);
      notify('Coach deleted');
      queryClient.invalidateQueries({ queryKey: ['admin-coaches'] });
      setDeleting(null);
    } catch (err) {
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <Card
        title="Coach List"
        subtitle={data ? `${data.meta.total} coaches` : ''}
        actions={
          <button type="button" className="btn btn-primary btn-sm" onClick={() => setEditing({})}>
            <Icon name="plus" size={16} className="me-1" /> Add Coach
          </button>
        }
      >
        <div className="row g-2 mb-3">
          <div className="col-md-4">
            <input className="form-control" placeholder="Search name, email or mobile" value={filters.search} onChange={setFilter('search')} />
          </div>
          <div className="col-md-3 col-6">
            <select className="form-select" value={filters.coach_type} onChange={setFilter('coach_type')}>
              <option value="">All types</option>
              {COACH_TYPES.map((t) => <option key={t} value={t}>{titleCase(t)}</option>)}
            </select>
          </div>
          <div className="col-md-2 col-6">
            <select className="form-select" value={filters.status} onChange={setFilter('status')}>
              <option value="">Any status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
          <div className="col-md-3">
            <select className="form-select" value={filters.plan} onChange={setFilter('plan')}>
              <option value="">With or without plan</option>
              <option value="with">Has active plan</option>
              <option value="without">No active plan</option>
            </select>
          </div>
        </div>

        {isLoading ? (
          <Loader />
        ) : error ? (
          <ErrorState message={errorMessage(error)} onRetry={refetch} />
        ) : data.data.length === 0 ? (
          <EmptyState icon="users" message="No coaches match these filters." />
        ) : (
          <div className={`table-responsive ${isFetching ? 'opacity-75' : ''}`}>
            <table className="table table-striped mb-0">
              <thead>
                <tr>
                  <th>Coach</th>
                  <th>Type</th>
                  <th>Plan</th>
                  <th>Customers</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th className="text-end">Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.data.map((c) => (
                  <tr key={c.id}>
                    <td>
                      <Link to={`/coaches/${c.id}`} className="fw-semibold">{c.name}</Link>
                      <div className="small text-muted">{c.email}{c.mobile ? ` | ${c.mobile}` : ''}</div>
                    </td>
                    <td>{titleCase(c.coach_type)}</td>
                    <td>
                      {c.subscription ? (
                        <>
                          <TierBadge tier={c.subscription.plan?.tier} />
                          <div className="small text-muted">until {date(c.subscription.ends_at)}</div>
                        </>
                      ) : (
                        <span className="text-muted small">No plan</span>
                      )}
                    </td>
                    <td>
                      {c.customers_count}
                      {c.subscription?.plan?.max_customers ? ` / ${c.subscription.plan.max_customers}` : ''}
                    </td>
                    <td><StatusBadge status={c.status} /></td>
                    <td>{date(c.created_at)}</td>
                    <td className="text-end text-nowrap">
                      <button type="button" className="btn btn-sm btn-soft-primary me-1" title="Assign plan" onClick={() => setAssigning(c)}>
                        <Icon name="crown" size={16} />
                      </button>
                      <button type="button" className="btn btn-sm btn-soft-info me-1" title="Edit" onClick={() => setEditing(c)}>
                        <Icon name="edit" size={16} />
                      </button>
                      <button type="button" className="btn btn-sm btn-soft-danger" title="Delete" onClick={() => setDeleting(c)}>
                        <Icon name="trash" size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <Pagination meta={data?.meta} onPage={(page) => setFilters({ ...filters, page })} />
      </Card>

      <CoachFormModal show={editing !== null} coach={editing?.id ? editing : null} onClose={() => setEditing(null)} />
      <AssignPlanModal show={assigning !== null} coach={assigning} onClose={() => setAssigning(null)} />
      <ConfirmModal
        show={deleting !== null}
        title="Delete coach?"
        message={`${deleting?.name} and all of their habits, customers and records will be permanently deleted.`}
        busy={busy}
        onConfirm={remove}
        onClose={() => setDeleting(null)}
      />
    </>
  );
}
