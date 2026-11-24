import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link, useParams } from 'react-router-dom';
import { api, errorMessage } from '../../api/client';
import avatar from '../../assets/hope-ui/images/avatars/01.png';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, EmptyState, ErrorState, Loader, StatusBadge, TierBadge } from '../../components/ui';
import { date, money, titleCase } from '../../utils/format';
import { AssignPlanModal, CoachFormModal } from './coachModals';

export default function CoachDetail() {
  const { id } = useParams();
  const [editing, setEditing] = useState(false);
  const [assigning, setAssigning] = useState(false);
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-coach', id],
    queryFn: () => api.get(`/admin/coaches/${id}`).then((r) => r.data),
  });
  usePageTitle(data?.data?.name || 'Coach', 'Profile, plan and subscription history.');

  if (isLoading) return <Card><Loader /></Card>;
  if (error) return <ErrorState message={errorMessage(error)} onRetry={refetch} />;

  const coach = data.data;
  const current = coach.subscription;

  return (
    <>
      <div className="mb-3">
        <Link to="/coaches">&larr; Back to coaches</Link>
      </div>
      <div className="row g-3">
        <div className="col-lg-4">
          <Card>
            <div className="text-center">
              <img src={coach.avatar_url || avatar} alt="" className="avatar avatar-100 avatar-rounded mb-3" />
              <h4 className="mb-1">{coach.name}</h4>
              <p className="text-muted mb-2">{titleCase(coach.coach_type)}</p>
              <StatusBadge status={coach.status} />
            </div>
            <hr />
            <dl className="row mb-0">
              <dt className="col-5">Email</dt>
              <dd className="col-7 text-break">{coach.email}</dd>
              <dt className="col-5">Mobile</dt>
              <dd className="col-7">{coach.mobile || '-'}</dd>
              <dt className="col-5">Customers</dt>
              <dd className="col-7">{coach.customers_count}</dd>
              <dt className="col-5">Habits</dt>
              <dd className="col-7">{coach.habits_count}</dd>
              <dt className="col-5">Joined</dt>
              <dd className="col-7">{date(coach.created_at)}</dd>
            </dl>
            <div className="d-flex gap-2 mt-3">
              <button type="button" className="btn btn-outline-primary flex-fill" onClick={() => setEditing(true)}>Edit</button>
              <button type="button" className="btn btn-primary flex-fill" onClick={() => setAssigning(true)}>Assign Plan</button>
            </div>
          </Card>
        </div>
        <div className="col-lg-8">
          <Card title="Current Plan">
            {current ? (
              <div className="d-flex flex-wrap justify-content-between align-items-center gap-3">
                <div>
                  <h4 className="mb-1">{current.plan?.name} <TierBadge tier={current.plan?.tier} /></h4>
                  <p className="mb-0 text-muted">
                    {date(current.starts_at)} to {date(current.ends_at)} ({current.days_left} days left)
                  </p>
                </div>
                <div className="text-end">
                  <div className="small text-muted">Customer limit</div>
                  <h5 className="mb-0">{current.plan?.max_customers ?? 'Unlimited'}</h5>
                </div>
              </div>
            ) : (
              <EmptyState icon="crown" message="This coach has no active plan, so they cannot add customers." />
            )}
          </Card>
          <Card title="Subscription History" bodyClassName="p-0">
            {data.subscriptions.length === 0 ? (
              <EmptyState icon="card" message="No subscriptions yet." />
            ) : (
              <div className="table-responsive">
                <table className="table table-striped mb-0">
                  <thead>
                    <tr>
                      <th>Plan</th>
                      <th>Period</th>
                      <th>Amount</th>
                      <th>Source</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.subscriptions.map((s) => (
                      <tr key={s.id}>
                        <td>{s.plan?.name}</td>
                        <td className="small">{date(s.starts_at)} - {date(s.ends_at)}</td>
                        <td>{money(s.amount)}</td>
                        <td>{titleCase(s.source)}</td>
                        <td>
                          <StatusBadge status={s.status} />
                          {s.notes && <div className="small text-muted">{s.notes}</div>}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Card>
        </div>
      </div>
      <CoachFormModal show={editing} coach={coach} onClose={() => { setEditing(false); refetch(); }} />
      <AssignPlanModal show={assigning} coach={coach} onClose={() => { setAssigning(false); refetch(); }} />
    </>
  );
}
