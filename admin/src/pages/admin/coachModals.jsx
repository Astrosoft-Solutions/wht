import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage, fieldErrors } from '../../api/client';
import { Field, Modal, SubmitButton } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';
import { COACH_TYPES, money, titleCase } from '../../utils/format';

const EMPTY = { name: '', email: '', mobile: '', password: '', coach_type: 'coach', status: 'active' };

export function CoachFormModal({ show, coach, onClose }) {
  const queryClient = useQueryClient();
  const notify = useToast();
  const [form, setForm] = useState(EMPTY);
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (show) {
      setForm(coach ? { ...EMPTY, ...coach, mobile: coach.mobile || '', password: '' } : EMPTY);
      setErrors({});
    }
  }, [show, coach]);

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setErrors({});
    const payload = {
      name: form.name,
      email: form.email,
      mobile: form.mobile || null,
      coach_type: form.coach_type,
      status: form.status,
      ...(form.password ? { password: form.password } : {}),
    };
    try {
      if (coach) await api.put(`/admin/coaches/${coach.id}`, payload);
      else await api.post('/admin/coaches', payload);
      notify(coach ? 'Coach updated' : 'Coach created');
      queryClient.invalidateQueries({ queryKey: ['admin-coaches'] });
      queryClient.invalidateQueries({ queryKey: ['admin-coach'] });
      onClose();
    } catch (err) {
      setErrors(fieldErrors(err));
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal show={show} title={coach ? 'Edit Coach' : 'Add Coach'} onClose={onClose}>
      <form onSubmit={submit}>
        <Field label="Full Name" required error={errors.name}>
          <input className="form-control" value={form.name} onChange={set('name')} required />
        </Field>
        <div className="row">
          <div className="col-md-6">
            <Field label="Email" required error={errors.email}>
              <input type="email" className="form-control" value={form.email} onChange={set('email')} required />
            </Field>
          </div>
          <div className="col-md-6">
            <Field label="Mobile" error={errors.mobile}>
              <input className="form-control" value={form.mobile} onChange={set('mobile')} />
            </Field>
          </div>
          <div className="col-md-6">
            <Field label="Coach Type" required error={errors.coach_type}>
              <select className="form-select" value={form.coach_type} onChange={set('coach_type')}>
                {COACH_TYPES.map((t) => <option key={t} value={t}>{titleCase(t)}</option>)}
              </select>
            </Field>
          </div>
          <div className="col-md-6">
            <Field label="Status" error={errors.status}>
              <select className="form-select" value={form.status} onChange={set('status')}>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </Field>
          </div>
        </div>
        <Field
          label={coach ? 'New Password' : 'Password'}
          required={!coach}
          error={errors.password}
          hint={coach ? 'Leave blank to keep the current password.' : 'At least 8 characters.'}
        >
          <input type="password" className="form-control" value={form.password} onChange={set('password')} autoComplete="new-password" />
        </Field>
        <div className="d-flex justify-content-end gap-2">
          <button type="button" className="btn btn-light" onClick={onClose}>Cancel</button>
          <SubmitButton busy={busy}>{coach ? 'Save Changes' : 'Create Coach'}</SubmitButton>
        </div>
      </form>
    </Modal>
  );
}

export function AssignPlanModal({ show, coach, onClose }) {
  const queryClient = useQueryClient();
  const notify = useToast();
  const [form, setForm] = useState({ plan_id: '', duration_days: '', amount: '', starts_at: '', notes: '' });
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);
  const { data: plans = [] } = useQuery({
    queryKey: ['admin-plans'],
    queryFn: () => api.get('/admin/plans').then((r) => r.data.data),
    enabled: show,
  });

  const options = plans.filter((p) => p.is_active && (!coach?.coach_type || p.coach_type === coach.coach_type));

  useEffect(() => {
    if (show) {
      setForm({ plan_id: '', duration_days: '', amount: '', starts_at: '', notes: '' });
      setErrors({});
    }
  }, [show]);

  const selected = plans.find((p) => String(p.id) === String(form.plan_id));
  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    try {
      await api.post(`/admin/coaches/${coach.id}/assign-plan`, {
        plan_id: Number(form.plan_id),
        duration_days: form.duration_days ? Number(form.duration_days) : null,
        amount: form.amount === '' ? null : Number(form.amount),
        starts_at: form.starts_at || null,
        notes: form.notes || null,
      });
      notify(`${selected?.name} assigned to ${coach.name}`);
      ['admin-coaches', 'admin-coach', 'admin-subscriptions', 'admin-dashboard'].forEach((key) =>
        queryClient.invalidateQueries({ queryKey: [key] }),
      );
      onClose();
    } catch (err) {
      setErrors(fieldErrors(err));
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal show={show} title={`Assign Plan${coach ? ` - ${coach.name}` : ''}`} onClose={onClose}>
      <form onSubmit={submit}>
        <Field label="Plan" required error={errors.plan_id} hint="Renewing the same plan extends it; a different plan replaces the current one.">
          <select className="form-select" value={form.plan_id} onChange={set('plan_id')} required>
            <option value="">Select a plan</option>
            {options.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name} - {money(p.price)} / {p.duration_days} days
              </option>
            ))}
          </select>
        </Field>
        <div className="row">
          <div className="col-md-6">
            <Field label="Duration (days)" error={errors.duration_days} hint={selected ? `Default ${selected.duration_days}` : ''}>
              <input type="number" min="1" className="form-control" value={form.duration_days} onChange={set('duration_days')} />
            </Field>
          </div>
          <div className="col-md-6">
            <Field label="Amount received (INR)" error={errors.amount} hint="0 for complimentary">
              <input type="number" min="0" step="0.01" className="form-control" value={form.amount} onChange={set('amount')} />
            </Field>
          </div>
          <div className="col-md-6">
            <Field label="Start date" error={errors.starts_at} hint="Defaults to today or after the current period">
              <input type="date" className="form-control" value={form.starts_at} onChange={set('starts_at')} />
            </Field>
          </div>
          <div className="col-md-6">
            <Field label="Notes" error={errors.notes}>
              <input className="form-control" value={form.notes} onChange={set('notes')} placeholder="e.g. Paid by cash" />
            </Field>
          </div>
        </div>
        <div className="d-flex justify-content-end gap-2">
          <button type="button" className="btn btn-light" onClick={onClose}>Cancel</button>
          <SubmitButton busy={busy}>Assign Plan</SubmitButton>
        </div>
      </form>
    </Modal>
  );
}
