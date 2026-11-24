import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage, fieldErrors } from '../../api/client';
import Icon from '../../components/Icon';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, ConfirmModal, EmptyState, ErrorState, Field, Loader, Modal, StatusBadge, SubmitButton } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';
import { daysLabel, time12, WEEKDAYS } from '../../utils/format';

/** Must match the icon keys the Flutter app understands (core/widgets/habit_icon.dart). */
const ICONS = {
  sunrise: { label: 'Sunrise', color: '#F9A825' },
  prayer: { label: 'Prayer', color: '#8D6E63' },
  fitness: { label: 'Fitness', color: '#455A64' },
  shake: { label: 'Shake', color: '#E91E63' },
  book: { label: 'Book', color: '#1565C0' },
  water: { label: 'Water', color: '#1E88E5' },
  leaf: { label: 'Afresh', color: '#43A047' },
  lunch: { label: 'Meal', color: '#EF6C00' },
  dance: { label: 'Dance', color: '#7B1FA2' },
  bed: { label: 'Sleep', color: '#3949AB' },
  walk: { label: 'Walk', color: '#00897B' },
  check: { label: 'General', color: '#2E7D32' },
};

export default function MasterHabits() {
  usePageTitle('Master Habits', 'Templates copied to every new coach and offered in the app.');
  const queryClient = useQueryClient();
  const notify = useToast();
  const [editing, setEditing] = useState(null);
  const [deleting, setDeleting] = useState(null);
  const [busy, setBusy] = useState(false);

  const { data: habits, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-master-habits'],
    queryFn: () => api.get('/admin/master-habits').then((r) => r.data.data),
  });

  const toggleActive = async (habit) => {
    try {
      await api.put(`/admin/master-habits/${habit.id}`, { is_active: !habit.is_active });
      queryClient.invalidateQueries({ queryKey: ['admin-master-habits'] });
    } catch (err) {
      notify(errorMessage(err), 'error');
    }
  };

  const remove = async () => {
    setBusy(true);
    try {
      await api.delete(`/admin/master-habits/${deleting.id}`);
      notify('Template deleted');
      queryClient.invalidateQueries({ queryKey: ['admin-master-habits'] });
      setDeleting(null);
    } catch (err) {
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Card
      title="Habit Templates"
      subtitle="Coaches keep their own copies, so editing a template does not change habits they already have."
      actions={
        <button type="button" className="btn btn-primary btn-sm" onClick={() => setEditing({})}>
          <Icon name="plus" size={16} /> Add Template
        </button>
      }
    >
      {isLoading ? (
        <Loader />
      ) : error ? (
        <ErrorState message={errorMessage(error)} onRetry={refetch} />
      ) : habits.length === 0 ? (
        <EmptyState icon="habit" message="No templates yet." />
      ) : (
        <div className="table-responsive">
          <table className="table table-striped mb-0">
            <thead>
              <tr>
                <th>Habit</th>
                <th>Time</th>
                <th>Repeat</th>
                <th>Status</th>
                <th className="text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
              {habits.map((h) => (
                <tr key={h.id}>
                  <td>
                    <span className="d-inline-block rounded-circle me-2 align-middle" style={{ width: 12, height: 12, background: h.color }} />
                    <span className="fw-semibold">{h.name}</span>
                    <div className="small text-muted ms-4">{ICONS[h.icon]?.label || h.icon}</div>
                  </td>
                  <td>{time12(h.start_time)}{h.end_time ? ` - ${time12(h.end_time)}` : ''}</td>
                  <td>{daysLabel(h.days_of_week)}</td>
                  <td>
                    <button type="button" className="btn btn-link p-0" onClick={() => toggleActive(h)} title="Toggle">
                      <StatusBadge status={h.is_active ? 'active' : 'inactive'} />
                    </button>
                  </td>
                  <td className="text-end text-nowrap">
                    <button type="button" className="btn btn-sm btn-soft-info me-1" onClick={() => setEditing(h)}>
                      <Icon name="edit" size={16} />
                    </button>
                    <button type="button" className="btn btn-sm btn-soft-danger" onClick={() => setDeleting(h)}>
                      <Icon name="trash" size={16} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <HabitFormModal show={editing !== null} habit={editing?.id ? editing : null} onClose={() => setEditing(null)} />
      <ConfirmModal
        show={deleting !== null}
        title="Delete template?"
        message={`Delete "${deleting?.name}"? Coaches who already have this habit keep their copy.`}
        busy={busy}
        onConfirm={remove}
        onClose={() => setDeleting(null)}
      />
    </Card>
  );
}

function HabitFormModal({ show, habit, onClose }) {
  const queryClient = useQueryClient();
  const notify = useToast();
  const [form, setForm] = useState({});
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!show) return;
    setErrors({});
    setForm({
      name: habit?.name || '',
      icon: habit?.icon || 'water',
      color: habit?.color || ICONS.water.color,
      start_time: habit?.start_time || '06:00',
      end_time: habit?.end_time || '',
      days: habit?.days_of_week?.length ? habit.days_of_week : [1, 2, 3, 4, 5, 6, 7],
      is_active: habit?.is_active ?? true,
    });
  }, [show, habit]);

  const toggleDay = (d) =>
    setForm({ ...form, days: form.days.includes(d) ? form.days.filter((x) => x !== d) : [...form.days, d].sort() });

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setErrors({});
    const payload = {
      name: form.name,
      icon: form.icon,
      color: form.color.toUpperCase(),
      start_time: form.start_time,
      end_time: form.end_time || null,
      days_of_week: form.days.length === 7 ? null : form.days,
      is_active: form.is_active,
    };
    try {
      if (habit) await api.put(`/admin/master-habits/${habit.id}`, payload);
      else await api.post('/admin/master-habits', payload);
      notify(habit ? 'Template updated' : 'Template added');
      queryClient.invalidateQueries({ queryKey: ['admin-master-habits'] });
      onClose();
    } catch (err) {
      setErrors(fieldErrors(err));
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal show={show} title={habit ? 'Edit Template' : 'Add Template'} onClose={onClose}>
      <form onSubmit={submit}>
        <Field label="Habit name" required error={errors.name}>
          <input className="form-control" value={form.name || ''} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
        </Field>
        <div className="row">
          <div className="col-8">
            <Field label="Icon" error={errors.icon}>
              <select
                className="form-select"
                value={form.icon}
                onChange={(e) => setForm({ ...form, icon: e.target.value, color: ICONS[e.target.value].color })}
              >
                {Object.entries(ICONS).map(([key, v]) => <option key={key} value={key}>{v.label}</option>)}
              </select>
            </Field>
          </div>
          <div className="col-4">
            <Field label="Color" error={errors.color}>
              <input type="color" className="form-control form-control-color w-100" value={form.color || '#000000'} onChange={(e) => setForm({ ...form, color: e.target.value })} />
            </Field>
          </div>
          <div className="col-6">
            <Field label="Start time" required error={errors.start_time}>
              <input type="time" className="form-control" value={form.start_time || ''} onChange={(e) => setForm({ ...form, start_time: e.target.value })} required />
            </Field>
          </div>
          <div className="col-6">
            <Field label="End time" error={errors.end_time}>
              <input type="time" className="form-control" value={form.end_time || ''} onChange={(e) => setForm({ ...form, end_time: e.target.value })} />
            </Field>
          </div>
        </div>
        <Field label="Repeat on" error={errors.days_of_week}>
          <div className="d-flex flex-wrap gap-2">
            {WEEKDAYS.map((label, i) => (
              <button
                key={label}
                type="button"
                className={`btn btn-sm ${form.days?.includes(i + 1) ? 'btn-primary' : 'btn-outline-primary'}`}
                onClick={() => toggleDay(i + 1)}
              >
                {label}
              </button>
            ))}
          </div>
        </Field>
        <div className="form-check form-switch mb-3">
          <input className="form-check-input" type="checkbox" id="habit-active" checked={!!form.is_active} onChange={(e) => setForm({ ...form, is_active: e.target.checked })} />
          <label className="form-check-label" htmlFor="habit-active">Active (offered to coaches)</label>
        </div>
        <div className="d-flex justify-content-end gap-2">
          <button type="button" className="btn btn-light" onClick={onClose}>Cancel</button>
          <SubmitButton busy={busy}>Save</SubmitButton>
        </div>
      </form>
    </Modal>
  );
}
