import { useEffect, useRef, useState } from 'react';
import { keepPreviousData, useQuery, useQueryClient } from '@tanstack/react-query';
import { api, errorMessage, fieldErrors } from '../../api/client';
import Icon from '../../components/Icon';
import { usePageTitle } from '../../components/layout/PageTitle';
import { ConfirmModal, EmptyState, ErrorState, Field, Loader, Modal, Pagination, SubmitButton, Card } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';

const TABS = [
  { value: '', label: 'All' },
  { value: 'image', label: 'Images' },
  { value: 'video', label: 'Videos' },
];

export default function Gallery() {
  usePageTitle('Gallery', 'Images and videos every coach sees in the mobile app.');
  const queryClient = useQueryClient();
  const notify = useToast();
  const [type, setType] = useState('');
  const [page, setPage] = useState(1);
  const [editing, setEditing] = useState(null);
  const [deleting, setDeleting] = useState(null);
  const [preview, setPreview] = useState(null);
  const [busy, setBusy] = useState(false);

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-gallery', type, page],
    queryFn: () => api.get('/admin/gallery', { params: { type: type || undefined, page, per_page: 12 } }).then((r) => r.data),
    placeholderData: keepPreviousData,
  });

  const remove = async () => {
    setBusy(true);
    try {
      await api.delete(`/admin/gallery/${deleting.id}`);
      notify('Item deleted');
      queryClient.invalidateQueries({ queryKey: ['admin-gallery'] });
      setDeleting(null);
    } catch (err) {
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Card
      title="Media Library"
      actions={
        <button type="button" className="btn btn-primary btn-sm" onClick={() => setEditing({})}>
          <Icon name="upload" size={16} /> Upload
        </button>
      }
    >
      <ul className="nav nav-pills mb-3">
        {TABS.map((t) => (
          <li key={t.value} className="nav-item">
            <button type="button" className={`nav-link ${type === t.value ? 'active' : ''}`} onClick={() => { setType(t.value); setPage(1); }}>
              {t.label}
            </button>
          </li>
        ))}
      </ul>

      {isLoading ? (
        <Loader />
      ) : error ? (
        <ErrorState message={errorMessage(error)} onRetry={refetch} />
      ) : data.data.length === 0 ? (
        <EmptyState icon="gallery" message="Nothing here yet. Upload an image or add a video." />
      ) : (
        <div className="row g-3">
          {data.data.map((item) => (
            <div key={item.id} className="col-sm-6 col-lg-4 col-xxl-3">
              <div className="card h-100 mb-0 border">
                <div className="position-relative cursor-pointer" onClick={() => setPreview(item)}>
                  {item.thumbnail_url ? (
                    <img src={item.thumbnail_url} alt={item.title} className="gallery-thumb rounded-top" />
                  ) : (
                    <div className="gallery-thumb rounded-top d-flex align-items-center justify-content-center text-muted">
                      <Icon name="play" size={36} />
                    </div>
                  )}
                  {item.type === 'video' && (
                    <span className="position-absolute top-50 start-50 translate-middle bg-dark bg-opacity-50 text-white rounded-circle p-2 d-flex">
                      <Icon name="play" size={22} />
                    </span>
                  )}
                  {!item.is_published && <span className="badge bg-secondary position-absolute top-0 start-0 m-2">Hidden</span>}
                </div>
                <div className="card-body p-3">
                  <h6 className="mb-1 text-truncate" title={item.title}>{item.title}</h6>
                  <small className="text-muted">{item.type === 'video' ? (item.youtube_id ? 'YouTube video' : 'Video file') : 'Image'}</small>
                  <div className="d-flex justify-content-end gap-1 mt-2">
                    <button type="button" className="btn btn-sm btn-soft-info" onClick={() => setEditing(item)}>
                      <Icon name="edit" size={16} />
                    </button>
                    <button type="button" className="btn btn-sm btn-soft-danger" onClick={() => setDeleting(item)}>
                      <Icon name="trash" size={16} />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
      <Pagination meta={data?.meta} onPage={setPage} />

      <GalleryFormModal show={editing !== null} item={editing?.id ? editing : null} onClose={() => setEditing(null)} />
      <PreviewModal item={preview} onClose={() => setPreview(null)} />
      <ConfirmModal
        show={deleting !== null}
        title="Delete item?"
        message={`Delete "${deleting?.title}"? Coaches will no longer see it.`}
        busy={busy}
        onConfirm={remove}
        onClose={() => setDeleting(null)}
      />
    </Card>
  );
}

function PreviewModal({ item, onClose }) {
  return (
    <Modal show={!!item} title={item?.title} onClose={onClose} size="modal-lg">
      {item?.type === 'image' && <img src={item.file_url} alt={item.title} className="img-fluid rounded w-100" />}
      {item?.type === 'video' && item.youtube_id && (
        <div className="ratio ratio-16x9">
          <iframe src={`https://www.youtube.com/embed/${item.youtube_id}`} title={item.title} allowFullScreen />
        </div>
      )}
      {item?.type === 'video' && !item.youtube_id && item.file_url && (
        <video src={item.file_url} controls className="w-100 rounded" />
      )}
      {item?.description && <p className="mt-3 mb-0">{item.description}</p>}
    </Modal>
  );
}

function GalleryFormModal({ show, item, onClose }) {
  const queryClient = useQueryClient();
  const notify = useToast();
  const fileInput = useRef(null);
  const [form, setForm] = useState({});
  const [file, setFile] = useState(null);
  const [thumbnail, setThumbnail] = useState(null);
  const [videoSource, setVideoSource] = useState('youtube');
  const [errors, setErrors] = useState({});
  const [progress, setProgress] = useState(null);
  const [dragOver, setDragOver] = useState(false);

  useEffect(() => {
    if (!show) return;
    setErrors({});
    setFile(null);
    setThumbnail(null);
    setProgress(null);
    setForm({
      type: item?.type || 'image',
      title: item?.title || '',
      description: item?.description || '',
      video_url: item?.video_url || '',
      is_published: item?.is_published ?? true,
    });
    setVideoSource(item && item.type === 'video' && !item.video_url ? 'file' : 'youtube');
  }, [show, item]);

  const isVideoFile = form.type === 'video' && videoSource === 'file';
  const needsFile = form.type === 'image' || isVideoFile;

  const onDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    if (e.dataTransfer.files?.[0]) setFile(e.dataTransfer.files[0]);
  };

  const submit = async (e) => {
    e.preventDefault();
    setErrors({});
    const body = new FormData();
    body.append('type', form.type);
    body.append('title', form.title);
    body.append('description', form.description || '');
    body.append('is_published', form.is_published ? '1' : '0');
    if (form.type === 'video' && videoSource === 'youtube') body.append('video_url', form.video_url);
    if (needsFile && file) body.append('file', file);
    if (form.type === 'video' && thumbnail) body.append('thumbnail', thumbnail);
    if (item) body.append('_method', 'PUT');

    setProgress(0);
    try {
      await api.post(item ? `/admin/gallery/${item.id}` : '/admin/gallery', body, {
        onUploadProgress: (ev) => ev.total && setProgress(Math.round((ev.loaded / ev.total) * 100)),
      });
      notify(item ? 'Item updated' : 'Item added to gallery');
      queryClient.invalidateQueries({ queryKey: ['admin-gallery'] });
      onClose();
    } catch (err) {
      setErrors(fieldErrors(err));
      notify(err?.response?.status === 413 ? 'File is larger than the server allows (check upload_max_filesize).' : errorMessage(err), 'error');
    } finally {
      setProgress(null);
    }
  };

  return (
    <Modal show={show} title={item ? 'Edit Gallery Item' : 'Upload to Gallery'} onClose={onClose} size="modal-lg">
      <form onSubmit={submit}>
        <div className="row">
          <div className="col-md-4">
            <Field label="Type" error={errors.type}>
              <select className="form-select" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })} disabled={!!item}>
                <option value="image">Image</option>
                <option value="video">Video</option>
              </select>
            </Field>
          </div>
          <div className="col-md-8">
            <Field label="Title" required error={errors.title}>
              <input className="form-control" value={form.title || ''} onChange={(e) => setForm({ ...form, title: e.target.value })} required />
            </Field>
          </div>
        </div>

        {form.type === 'video' && (
          <div className="btn-group mb-3" role="group">
            <button type="button" className={`btn btn-sm ${videoSource === 'youtube' ? 'btn-primary' : 'btn-outline-primary'}`} onClick={() => setVideoSource('youtube')}>
              YouTube link
            </button>
            <button type="button" className={`btn btn-sm ${videoSource === 'file' ? 'btn-primary' : 'btn-outline-primary'}`} onClick={() => setVideoSource('file')}>
              Upload video file
            </button>
          </div>
        )}

        {form.type === 'video' && videoSource === 'youtube' ? (
          <Field label="YouTube URL" required error={errors.video_url} hint="e.g. https://www.youtube.com/watch?v=...">
            <input type="url" className="form-control" value={form.video_url || ''} onChange={(e) => setForm({ ...form, video_url: e.target.value })} />
          </Field>
        ) : (
          <Field
            label={form.type === 'image' ? 'Image' : 'Video file'}
            error={errors.file}
            hint={form.type === 'image' ? 'JPG, PNG, WEBP or GIF up to 5 MB' : 'MP4, WEBM or MOV up to 100 MB'}
          >
            <div
              className={`dropzone-area ${dragOver ? 'drag-over' : ''}`}
              onClick={() => fileInput.current?.click()}
              onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
              onDragLeave={() => setDragOver(false)}
              onDrop={onDrop}
            >
              <Icon name="upload" size={28} className="text-primary mb-2" />
              <p className="mb-0">
                {file ? <strong>{file.name}</strong> : item?.file_url ? 'Drop a file to replace the current one' : 'Drag a file here or click to browse'}
              </p>
              <input
                ref={fileInput}
                type="file"
                hidden
                accept={form.type === 'image' ? 'image/*' : 'video/mp4,video/webm,video/quicktime'}
                onChange={(e) => setFile(e.target.files?.[0] || null)}
              />
            </div>
          </Field>
        )}

        {form.type === 'video' && (
          <Field label="Thumbnail (optional)" error={errors.thumbnail} hint="YouTube videos use their own thumbnail if you skip this.">
            <input type="file" className="form-control" accept="image/*" onChange={(e) => setThumbnail(e.target.files?.[0] || null)} />
          </Field>
        )}

        <Field label="Description" error={errors.description}>
          <textarea className="form-control" rows={3} value={form.description || ''} onChange={(e) => setForm({ ...form, description: e.target.value })} />
        </Field>
        <div className="form-check form-switch mb-3">
          <input className="form-check-input" type="checkbox" id="gallery-published" checked={!!form.is_published} onChange={(e) => setForm({ ...form, is_published: e.target.checked })} />
          <label className="form-check-label" htmlFor="gallery-published">Visible to coaches</label>
        </div>
        {progress !== null && (
          <div className="progress mb-3" style={{ height: 8 }}>
            <div className="progress-bar bg-primary" style={{ width: `${progress}%` }} />
          </div>
        )}
        <div className="d-flex justify-content-end gap-2">
          <button type="button" className="btn btn-light" onClick={onClose}>Cancel</button>
          <SubmitButton busy={progress !== null}>{item ? 'Save Changes' : 'Upload'}</SubmitButton>
        </div>
      </form>
    </Modal>
  );
}
