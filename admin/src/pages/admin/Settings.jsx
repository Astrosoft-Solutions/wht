import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage, fieldErrors } from '../../api/client';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, ErrorState, Field, Loader, SubmitButton } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';

export default function Settings() {
  usePageTitle('Notification Settings', 'Reminder rules the mobile app downloads, and payment setup status.');
  const queryClient = useQueryClient();
  const notify = useToast();
  const [form, setForm] = useState(null);
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-settings'],
    queryFn: () => api.get('/admin/settings').then((r) => r.data),
  });

  useEffect(() => {
    if (data) setForm(data.data);
  }, [data]);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setErrors({});
    try {
      await api.put('/admin/settings', {
        reminders_default_on: form.reminders_default_on,
        reminder_lead_minutes: Number(form.reminder_lead_minutes),
        reminder_interval_minutes: Number(form.reminder_interval_minutes),
      });
      notify('Settings saved. Apps pick them up the next time they open.');
      queryClient.invalidateQueries({ queryKey: ['admin-settings'] });
    } catch (err) {
      setErrors(fieldErrors(err));
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  if (isLoading || !form) return error ? <ErrorState message={errorMessage(error)} onRetry={refetch} /> : <Card><Loader /></Card>;

  const lead = Number(form.reminder_lead_minutes) || 0;
  const interval = Number(form.reminder_interval_minutes) || 15;

  return (
    <div className="row g-3">
      <div className="col-lg-7">
        <Card title="Habit Reminders">
          <form onSubmit={submit}>
            <div className="form-check form-switch mb-3">
              <input
                className="form-check-input"
                type="checkbox"
                id="rem-default"
                checked={!!form.reminders_default_on}
                onChange={(e) => setForm({ ...form, reminders_default_on: e.target.checked })}
              />
              <label className="form-check-label" htmlFor="rem-default">
                Reminders on by default for new installs
              </label>
            </div>
            <div className="row">
              <div className="col-md-6">
                <Field label="First reminder (minutes before start)" error={errors.reminder_lead_minutes} hint="0 to 180">
                  <input type="number" min="0" max="180" className="form-control" value={form.reminder_lead_minutes} onChange={(e) => setForm({ ...form, reminder_lead_minutes: e.target.value })} />
                </Field>
              </div>
              <div className="col-md-6">
                <Field label="Repeat every (minutes)" error={errors.reminder_interval_minutes} hint="5 to 180, until the habit is done">
                  <input type="number" min="5" max="180" className="form-control" value={form.reminder_interval_minutes} onChange={(e) => setForm({ ...form, reminder_interval_minutes: e.target.value })} />
                </Field>
              </div>
            </div>
            <div className="alert alert-light border small">
              Example: a habit from 8:00 to 9:00 AM reminds at{' '}
              {exampleTimes(lead, interval).join(', ')}.
            </div>
            <SubmitButton busy={busy}>Save Settings</SubmitButton>
          </form>
        </Card>
      </div>
      <div className="col-lg-5">
        <Card title="Razorpay">
          <p className="mb-2">
            API keys:{' '}
            {data.razorpay_configured ? <span className="badge bg-success">Configured</span> : <span className="badge bg-danger">Missing</span>}
          </p>
          <p className="mb-3">
            Webhook secret:{' '}
            {data.razorpay_webhook_configured ? <span className="badge bg-success">Configured</span> : <span className="badge bg-warning">Missing</span>}
          </p>
          <p className="small text-muted mb-1">
            Set <code>RAZORPAY_KEY_ID</code>, <code>RAZORPAY_KEY_SECRET</code> and <code>RAZORPAY_WEBHOOK_SECRET</code> in the Laravel <code>.env</code> file.
          </p>
          <p className="small text-muted mb-0">
            Webhook URL for the Razorpay dashboard (events <code>payment.captured</code>, <code>payment.failed</code>):
            <br />
            <code>{`${window.location.origin}/api/v1/razorpay/webhook`}</code>
          </p>
        </Card>
      </div>
    </div>
  );
}

function exampleTimes(lead, interval) {
  const start = 8 * 60;
  const times = [];
  for (let t = start - lead; t <= start + 60 && times.length < 8; t += interval) {
    const h = Math.floor(t / 60);
    const m = t % 60;
    times.push(`${((h + 11) % 12) + 1}:${String(m).padStart(2, '0')}`);
  }
  return times;
}
