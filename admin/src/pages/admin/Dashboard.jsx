import { useQuery } from '@tanstack/react-query';
import Chart from 'react-apexcharts';
import { Link } from 'react-router-dom';
import { api, errorMessage } from '../../api/client';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, EmptyState, ErrorState, Loader, StatCard, TierBadge } from '../../components/ui';
import { COACH_TYPES, date, money, TIERS, titleCase } from '../../utils/format';

const GREEN = ['#1B5E20', '#43A047', '#A5D6A7'];
const TIER_COLORS = ['#F9A825', '#90A4AE', '#B87333'];

export default function Dashboard() {
  usePageTitle('Dashboard', 'Coaches, subscriptions and revenue at a glance.');
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-dashboard'],
    queryFn: () => api.get('/admin/dashboard').then((r) => r.data),
  });

  if (isLoading) return <Card><Loader /></Card>;
  if (error) return <ErrorState message={errorMessage(error)} onRetry={refetch} />;

  const revenue = data.revenue.by_month;

  return (
    <>
      <div className="row g-3 mb-3">
        <div className="col-md-6 col-xl-3">
          <StatCard label="Total Coaches" value={data.coaches.total} icon="users" hint={`${data.coaches.active} active`} />
        </div>
        <div className="col-md-6 col-xl-3">
          <StatCard label="Active Subscriptions" value={data.subscriptions.active} icon="crown" tone="warning" />
        </div>
        <div className="col-md-6 col-xl-3">
          <StatCard label="Revenue This Month" value={money(data.revenue.this_month)} icon="rupee" tone="success" />
        </div>
        <div className="col-md-6 col-xl-3">
          <StatCard label="New Coaches This Month" value={data.coaches.new_this_month} icon="user" tone="info" />
        </div>
      </div>

      <div className="row g-3 mb-3">
        <div className="col-lg-8">
          <Card title="Revenue" subtitle="Online payments over the last 6 months" className="h-100">
            <Chart
              type="bar"
              height={300}
              series={[{ name: 'Revenue', data: revenue.map((m) => m.amount) }]}
              options={{
                chart: { toolbar: { show: false } },
                colors: [GREEN[0]],
                plotOptions: { bar: { borderRadius: 6, columnWidth: '45%' } },
                dataLabels: { enabled: false },
                xaxis: { categories: revenue.map((m) => m.label) },
                yaxis: { labels: { formatter: (v) => money(v) } },
                tooltip: { y: { formatter: (v) => money(v) } },
              }}
            />
          </Card>
        </div>
        <div className="col-lg-4">
          <Card title="Active Plans by Tier" className="h-100">
            {data.subscriptions.active === 0 ? (
              <EmptyState icon="crown" message="No active subscriptions yet." />
            ) : (
              <Chart
                type="donut"
                height={300}
                series={TIERS.map((t) => data.subscriptions.by_tier[t] || 0)}
                options={{ labels: TIERS.map(titleCase), colors: TIER_COLORS, legend: { position: 'bottom' } }}
              />
            )}
          </Card>
        </div>
      </div>

      <div className="row g-3 mb-3">
        <div className="col-lg-4">
          <Card title="Coaches by Type" className="h-100">
            <Chart
              type="bar"
              height={260}
              series={[
                { name: 'Coaches', data: COACH_TYPES.map((t) => data.coaches.by_type[t] || 0) },
                { name: 'Subscribed', data: COACH_TYPES.map((t) => data.subscriptions.by_type[t] || 0) },
              ]}
              options={{
                chart: { toolbar: { show: false } },
                colors: [GREEN[0], GREEN[1]],
                plotOptions: { bar: { borderRadius: 4, columnWidth: '50%' } },
                dataLabels: { enabled: false },
                xaxis: { categories: COACH_TYPES.map(titleCase) },
                legend: { position: 'bottom' },
              }}
            />
          </Card>
        </div>
        <div className="col-lg-8">
          <Card title="Expiring in 7 Days" actions={<Link to="/subscriptions?status=current" className="btn btn-sm btn-outline-primary">View all</Link>} className="h-100" bodyClassName="p-0">
            <SubscriptionTable rows={data.expiring_soon} empty="No plans expire in the next 7 days." />
          </Card>
        </div>
      </div>

      <Card title="Recent Subscriptions" bodyClassName="p-0">
        <SubscriptionTable rows={data.recent_subscriptions} empty="No subscriptions yet." />
      </Card>
    </>
  );
}

function SubscriptionTable({ rows, empty }) {
  if (!rows.length) return <EmptyState icon="card" message={empty} />;
  return (
    <div className="table-responsive">
      <table className="table table-striped mb-0">
        <thead>
          <tr>
            <th>Coach</th>
            <th>Plan</th>
            <th>Amount</th>
            <th>Source</th>
            <th>Ends</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((s) => (
            <tr key={s.id}>
              <td>
                <Link to={`/coaches/${s.user?.id}`}>{s.user?.name}</Link>
                <div className="small text-muted">{s.user?.email}</div>
              </td>
              <td>
                {s.plan?.name} <TierBadge tier={s.plan?.tier} />
              </td>
              <td>{money(s.amount)}</td>
              <td>{titleCase(s.source)}</td>
              <td>
                {date(s.ends_at)}
                {s.is_current && <div className="small text-muted">{s.days_left} days left</div>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
