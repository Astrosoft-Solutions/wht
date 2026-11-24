import { useEffect, useState } from 'react';
import { keepPreviousData, useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage, fieldErrors } from '../../api/client';
import Icon from '../../components/Icon';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, ConfirmModal, EmptyState, ErrorState, Field, Loader, Modal, Pagination, StatusBadge, SubmitButton } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';
import { dateTime, titleCase } from '../../utils/format';

const AUDIENCES = ['all', 'consultant', 'coach', 'guide'];

/** ISO string -> value for <input type="datetime-local"> in local time. */
function toLocalInput(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export default function Announcements() {
  usePageTitle('Announcements', 'Messages shown under the bell icon in the coaches\u2019 app.');
  const queryClient = useQueryClient();
  const notify = useToast();
  const [page, setPage] = useState(1);
  const [editing, setEditing] = useState(null);
  const [deleting, setDeleting] = useState(null);
  const [busy, setBusy] = useState(false);

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-announcements', page],
    queryFn: () => api.get('/admin/announcements', { params: { page } }).then((r) => r.data),
    placeholderData: keepPreviousData,
  });

  const remove = async () => {
    setBusy(true);
    try {
      await api.delete(`/admin/announcements/${deleting.id}`);
      notify('Announcement deleted');
      queryClient.invalidateQueries({ queryKey: ['admin-announcements'] });
      setDeleting(null);
    } catch (err) {
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  const isScheduled = (a) => a.published_at && new Date(a.published_at) > new Date();

  return (
    <Card
      title="Announcements"
      actions={
        <button type="button" className="btn btn-primary btn-sm" onClick={() => setEditing({})}>
          <Icon name="plus" size={16} /> New Announcement
        </button>
      }
    >
      {isLoading ? (
        <Loader />
      ) : error ? (
        <ErrorState message={errorMessage(error)} onRetry={refetch} />
      ) : data.data.length === 0 ? (
        <EmptyState icon="megaphone" message="No announcements yet." />
      ) : (
        <div className="table-responsive">
          <table className="table table-striped mb-0">
            <thead>
              <tr>
                <th>Announcement</th>
                <th>Audience</th>
                <th>Publish</th>
                <th>Read by</th>
                <th>Status</th>
                <th className="text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
              {data.data.map((a) => (
                <tr key={a.id}>
                  <td style={{ maxWidth: 360 }}>
                    <div className="fw-semibold">{a.title}</div>
                    <div className="small text-muted text-truncate">{a.body}</div>
                  </td>
                  <td>{a.audience === 'all' ? 'All coaches' : `${titleCase(a.audience)}s`}</td>
                  <td className="small">
                    {dateTime(a.published_at)}
                    {isScheduled(a) && <div className="text-warning">Scheduled</div>}
                  </td>
                  <td>{a.reads_count}</td>
                  <td><StatusBadge status={a.is_active ? 'active' : 'inactive'} /></td>
                  <td className="text-end text-nowrap">
                    <button type="button" className="btn btn-sm btn-soft-info me-1" onClick={() => setEditing(a)}>
                      <Icon name="edit" size={16} />
                    </button>
                    <button type="button" className="btn btn-sm btn-soft-danger" onClick={() => setDeleting(a)}>
                      <Icon name="trash" size={16} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <Pagination meta={data?.meta} onPage={setPage} />

      <AnnouncementModal show={editing !== null} announcement={editing?.id ? editing : null} onClose={() => setEditing(null)} />
      <ConfirmModal
        show={deleting !== null}
        title="Delete announcement?"
        message={`Delete "${deleting?.title}"?`}
        busy={busy}
        onConfirm={remove}
        onClose={() => setDeleting(null)}
      />
    </Card>
  );
}

function AnnouncementModal({ show, announcement, onClose }) {
  const queryClient = useQueryClient();
  const notify = useToast();
  const [form, setForm] = useState({});
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!show) return;
    setErrors({});
    setForm({
      title: announcement?.title || '',
      body: announcement?.body || '',
      audience: announcement?.audience || 'all',
      published_at: toLocalInput(announcement?.published_at),
      is_active: announcement?.is_active ?? true,
    });
  }, [show, announcement]);

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.type === 'checkbox' ? e.target.checked : e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setErrors({});
    const payload = {
      ...form,
      published_at: form.published_at ? new Date(form.published_at).toISOString() : null,
    };
    try {
      if (announcement) await api.put(`/admin/announcements/${announcement.id}`, payload);
      else await api.post('/admin/announcements', payload);
      notify(announcement ? 'Announcement updated' : 'Announcement published');
      queryClient.invalidateQueries({ queryKey: ['admin-announcements'] });
      onClose();
    } catch (err) {
      setErrors(fieldErrors(err));
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal show={show} title={announcement ? 'Edit Announcement' : 'New Announcement'} onClose={onClose} size="modal-lg">
      <form onSubmit={submit}>
        <Field label="Title" required error={errors.title}>
          <input className="form-control" value={form.title || ''} onChange={set('title')} required />
        </Field>
        <Field label="Message" required error={errors.body}>
          <textarea className="form-control" rows={5} value={form.body || ''} onChange={set('body')} required />
        </Field>
        <div className="row">
          <div className="col-md-6">
            <Field label="Audience" error={errors.audience}>
              <select className="form-select" value={form.audience} onChange={set('audience')}>
                {AUDIENCES.map((a) => (
                  <option key={a} value={a}>{a === 'all' ? 'All coaches' : `${titleCase(a)}s only`}</option>
                ))}
              </select>
            </Field>
          </div>
          <div className="col-md-6">
            <Field label="Publish at" error={errors.published_at} hint="Leave empty to publish now">
              <input type="datetime-local" className="form-control" value={form.published_at || ''} onChange={set('published_at')} />
            </Field>
          </div>
        </div>
        <div className="form-check form-switch mb-3">
          <input className="form-check-input" type="checkbox" id="ann-active" checked={!!form.is_active} onChange={set('is_active')} />
          <label className="form-check-label" htmlFor="ann-active">Active</label>
        </div>
        <div className="d-flex justify-content-end gap-2">
          <button type="button" className="btn btn-light" onClick={onClose}>Cancel</button>
          <SubmitButton busy={busy}>{announcement ? 'Save Changes' : 'Publish'}</SubmitButton>
        </div>
      </form>
    </Modal>
  );
}
