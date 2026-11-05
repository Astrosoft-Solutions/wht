import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { api, errorMessage } from '../../api/client';
import { useAuth } from '../../auth/AuthContext';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, EmptyState, ErrorState, Loader, StatCard, TierBadge } from '../../components/ui';
import { date, dateTime, titleCase } from '../../utils/format';
import { useSubscription } from './useSubscription';

export default function CoachDashboard() {
  const { user } = useAuth();
  usePageTitle(`Hello, ${user?.name?.split(' ')[0] || 'Coach'}!`, `${titleCase(user?.coach_type)} account overview.`);
  const subscription = useSubscription();
  const today = useQuery({
    queryKey: ['coach-today'],
    queryFn: () => api.get('/dashboard').then((r) => r.data),
  });
  const announcements = useQuery({
    queryKey: ['coach-announcements'],
    queryFn: () => api.get('/announcements').then((r) => r.data),
  });

  if (subscription.isLoading) return <Card><Loader /></Card>;
  if (subscription.error) return <ErrorState message={errorMessage(subscription.error)} onRetry={subscription.refetch} />;

  const { current, customers_count: customers, max_customers: limit } = subscription.data;
  const usage = limit ? Math.min(100, Math.round((customers / limit) * 100)) : null;

  return (
    <>
      <div className="row g-3 mb-3">
        <div className="col-md-4">
          <StatCard
            label="Current Plan"
            value={current ? current.plan.name : 'No plan'}
            icon="crown"
            tone="warning"
            hint={current ? `${current.days_left} days left` : 'Choose a plan to add customers'}
          />
        </div>
        <div className="col-md-4">
          <StatCard label="Customers" value={limit ? `${customers} / ${limit}` : customers} icon="users" hint={current && !limit ? 'Unlimited plan' : ''} />
        </div>
        <div className="col-md-4">
          <StatCard
            label="Habits Today"
            value={today.data ? `${today.data.habits_completed} / ${today.data.habits_total}` : '-'}
            icon="habit"
            tone="success"
            hint={today.data ? `${today.data.streak} day streak` : ''}
          />
        </div>
      </div>

      <div className="row g-3">
        <div className="col-lg-6">
          <Card title="My Subscription" actions={<Link to="/coach/plans" className="btn btn-sm btn-primary">{current ? 'Renew or Upgrade' : 'Choose a Plan'}</Link>}>
            {current ? (
              <>
                <h4 className="mb-1">{current.plan.name} <TierBadge tier={current.plan.tier} /></h4>
                <p className="text-muted">
                  Active from {date(current.starts_at)} to {date(current.ends_at)}
                </p>
                {usage !== null && (
                  <>
                    <div className="d-flex justify-content-between small mb-1">
                      <span>Customer limit used</span>
                      <span>{customers} of {limit}</span>
                    </div>
                    <div className="progress" style={{ height: 8 }}>
                      <div className={`progress-bar ${usage >= 90 ? 'bg-danger' : 'bg-primary'}`} style={{ width: `${usage}%` }} />
                    </div>
                  </>
                )}
              </>
            ) : (
              <EmptyState icon="crown" message="You don't have an active plan. You can still track habits, but adding customers needs a plan." />
            )}
          </Card>
        </div>
        <div className="col-lg-6">
          <Card title="Announcements">
            {announcements.isLoading ? (
              <Loader />
            ) : !announcements.data?.data?.length ? (
              <EmptyState icon="megaphone" message="No announcements." />
            ) : (
              <ul className="list-unstyled mb-0">
                {announcements.data.data.slice(0, 5).map((a) => (
                  <li key={a.id} className="mb-3 pb-3 border-bottom">
                    <div className="d-flex justify-content-between">
                      <strong>{a.title}</strong>
                      <small className="text-muted">{dateTime(a.published_at)}</small>
                    </div>
                    <p className="mb-0 small">{a.body}</p>
                  </li>
                ))}
              </ul>
            )}
          </Card>
        </div>
      </div>
    </>
  );
}
