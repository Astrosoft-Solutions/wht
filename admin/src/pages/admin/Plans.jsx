import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage, fieldErrors } from '../../api/client';
import Icon from '../../components/Icon';
import { usePageTitle } from '../../components/layout/PageTitle';
import { ConfirmModal, ErrorState, Field, Loader, Modal, SubmitButton, TierBadge, Card } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';
import { COACH_TYPES, money, TIERS, titleCase } from '../../utils/format';

export default function Plans() {
  usePageTitle('Plans', 'Gold, Silver and Bronze plans for each coach type.');
  const queryClient = useQueryClient();
  const notify = useToast();
  const [editing, setEditing] = useState(null);
  const [deleting, setDeleting] = useState(null);
  const [busy, setBusy] = useState(false);

  const { data: plans, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-plans'],
    queryFn: () => api.get('/admin/plans').then((r) => r.data.data),
  });

  const remove = async () => {
    setBusy(true);
    try {
      await api.delete(`/admin/plans/${deleting.id}`);
      notify('Plan deleted');
      queryClient.invalidateQueries({ queryKey: ['admin-plans'] });
      setDeleting(null);
    } catch (err) {
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  if (isLoading) return <Card><Loader /></Card>;
  if (error) return <ErrorState message={errorMessage(error)} onRetry={refetch} />;

  return (
    <>
      {COACH_TYPES.map((type) => (
        <div key={type} className="mb-4">
          <h4 className="mb-3">{titleCase(type)} Plans</h4>
          <div className="row g-3">
            {TIERS.map((tier) => {
              const plan = plans.find((p) => p.coach_type === type && p.tier === tier);
              return (
                <div key={tier} className="col-md-6 col-xl-4">
                  {plan ? (
                    <PlanCard plan={plan} onEdit={() => setEditing(plan)} onDelete={() => setDeleting(plan)} />
                  ) : (
                    <div className="card empty-cell h-100 d-flex align-items-center justify-content-center">
                      <div className="text-center p-4">
                        <TierBadge tier={tier} />
                        <p className="text-muted my-2">No {tier} plan for {type}s</p>
                        <button type="button" className="btn btn-sm btn-primary" onClick={() => setEditing({ coach_type: type, tier })}>
                          <Icon name="plus" size={16} /> Create
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      ))}

      <PlanFormModal show={editing !== null} plan={editing} onClose={() => setEditing(null)} />
      <ConfirmModal
        show={deleting !== null}
        title="Delete plan?"
        message={`Delete ${deleting?.name}? Plans with subscriptions cannot be deleted; deactivate them instead.`}
        busy={busy}
        onConfirm={remove}
        onClose={() => setDeleting(null)}
      />
    </>
  );
}

function PlanCard({ plan, onEdit, onDelete }) {
  return (
    <div className={`card pricing-card h-100 ${plan.is_active ? '' : 'opacity-75'}`}>
      <div className="card-body d-flex flex-column">
        <div className="d-flex justify-content-between align-items-start mb-2">
          <TierBadge tier={plan.tier} />
          {!plan.is_active && <span className="badge bg-secondary">Inactive</span>}
        </div>
        <h5 className="mb-1">{plan.name}</h5>
        <div className="mb-3">
          <span className="price text-primary">{money(plan.price)}</span>
          <span className="text-muted"> / {plan.duration_days} days</span>
        </div>
        <p className="mb-2">
          <strong>Customers:</strong> {plan.max_customers ?? 'Unlimited'}
        </p>
        <ul className="list-unstyled mb-3 flex-grow-1">
          {plan.features.map((f) => (
            <li key={f} className="mb-1 d-flex gap-2">
              <Icon name="check" size={16} className="text-success mt-1 flex-shrink-0" />
              <span>{f}</span>
            </li>
          ))}
        </ul>
        <div className="d-flex justify-content-between align-items-center">
          <small className="text-muted">{plan.subscriptions_count} subscriptions</small>
          <div>
            <button type="button" className="btn btn-sm btn-soft-info me-1" onClick={onEdit} title="Edit">
              <Icon name="edit" size={16} />
            </button>
            <button type="button" className="btn btn-sm btn-soft-danger" onClick={onDelete} title="Delete">
              <Icon name="trash" size={16} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function PlanFormModal({ show, plan, onClose }) {
  const queryClient = useQueryClient();
  const notify = useToast();
  const [form, setForm] = useState({});
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);
  const isNew = !plan?.id;

  useEffect(() => {
    if (!show) return;
    setErrors({});
    setForm({
      coach_type: plan?.coach_type || 'coach',
      tier: plan?.tier || 'gold',
      name: plan?.name || `${titleCase(plan?.coach_type)} ${titleCase(plan?.tier)}`,
      description: plan?.description || '',
      price: plan?.price ?? '',
      duration_days: plan?.duration_days ?? 30,
      max_customers: plan?.max_customers ?? '',
      features: (plan?.features || []).join('\n'),
      is_active: plan?.is_active ?? true,
    });
  }, [show, plan]);

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.type === 'checkbox' ? e.target.checked : e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setErrors({});
    const payload = {
      ...form,
      price: Number(form.price),
      duration_days: Number(form.duration_days),
      max_customers: form.max_customers === '' ? null : Number(form.max_customers),
      features: form.features.split('\n').map((f) => f.trim()).filter(Boolean),
    };
    try {
      if (isNew) await api.post('/admin/plans', payload);
      else await api.put(`/admin/plans/${plan.id}`, payload);
      notify(isNew ? 'Plan created' : 'Plan updated');
      queryClient.invalidateQueries({ queryKey: ['admin-plans'] });
      onClose();
    } catch (err) {
      setErrors(fieldErrors(err));
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal show={show} title={isNew ? 'Create Plan' : `Edit ${plan?.name}`} onClose={onClose} size="modal-lg">
      <form onSubmit={submit}>
        <div className="row">
          <div className="col-md-4">
            <Field label="Coach Type" error={errors.coach_type}>
              <select className="form-select" value={form.coach_type} onChange={set('coach_type')} disabled={!isNew}>
                {COACH_TYPES.map((t) => <option key={t} value={t}>{titleCase(t)}</option>)}
              </select>
            </Field>
          </div>
          <div className="col-md-4">
            <Field label="Tier" error={errors.tier}>
              <select className="form-select" value={form.tier} onChange={set('tier')} disabled={!isNew}>
                {TIERS.map((t) => <option key={t} value={t}>{titleCase(t)}</option>)}
              </select>
            </Field>
          </div>
          <div className="col-md-4">
            <Field label="Name" required error={errors.name}>
              <input className="form-control" value={form.name || ''} onChange={set('name')} required />
            </Field>
          </div>
          <div className="col-md-4">
            <Field label="Price (INR)" required error={errors.price_paise}>
              <input type="number" min="1" step="0.01" className="form-control" value={form.price} onChange={set('price')} required />
            </Field>
          </div>
          <div className="col-md-4">
            <Field label="Duration (days)" error={errors.duration_days}>
              <input type="number" min="1" className="form-control" value={form.duration_days} onChange={set('duration_days')} />
            </Field>
          </div>
          <div className="col-md-4">
            <Field label="Max customers" error={errors.max_customers} hint="Leave blank for unlimited">
              <input type="number" min="1" className="form-control" value={form.max_customers} onChange={set('max_customers')} />
            </Field>
          </div>
        </div>
        <Field label="Description" error={errors.description}>
          <input className="form-control" value={form.description || ''} onChange={set('description')} />
        </Field>
        <Field label="Features" error={errors.features} hint="One feature per line">
          <textarea className="form-control" rows={5} value={form.features || ''} onChange={set('features')} />
        </Field>
        <div className="form-check form-switch mb-3">
          <input className="form-check-input" type="checkbox" id="plan-active" checked={!!form.is_active} onChange={set('is_active')} />
          <label className="form-check-label" htmlFor="plan-active">Active (visible to coaches)</label>
        </div>
        <div className="d-flex justify-content-end gap-2">
          <button type="button" className="btn btn-light" onClick={onClose}>Cancel</button>
          <SubmitButton busy={busy}>{isNew ? 'Create Plan' : 'Save Changes'}</SubmitButton>
        </div>
      </form>
    </Modal>
  );
}
