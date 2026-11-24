import { cloneElement, isValidElement, useEffect, useId } from 'react';
import { TIER_STYLE, titleCase } from '../../utils/format';
import Icon from '../Icon';

export function Card({ title, subtitle, actions, children, bodyClassName = '', className = '' }) {
  return (
    <div className={`card ${className}`}>
      {(title || actions) && (
        <div className="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div className="header-title">
            {title && <h4 className="card-title mb-0">{title}</h4>}
            {subtitle && <p className="mb-0 text-muted small">{subtitle}</p>}
          </div>
          {actions && <div className="d-flex gap-2 flex-wrap">{actions}</div>}
        </div>
      )}
      <div className={`card-body ${bodyClassName}`}>{children}</div>
    </div>
  );
}

export function StatCard({ label, value, icon, tone = 'primary', hint }) {
  return (
    <div className="card card-slide h-100">
      <div className="card-body">
        <div className="d-flex align-items-center gap-3">
          <div className={`bg-soft-${tone} text-${tone} rounded p-3 d-flex`}>
            <Icon name={icon} size={24} />
          </div>
          <div>
            <p className="mb-1 text-muted">{label}</p>
            <h4 className="mb-0">{value}</h4>
            {hint && <small className="text-muted">{hint}</small>}
          </div>
        </div>
      </div>
    </div>
  );
}

export function Modal({ show, title, onClose, children, footer, size = '' }) {
  useEffect(() => {
    if (!show) return undefined;
    const onKey = (e) => e.key === 'Escape' && onClose?.();
    document.addEventListener('keydown', onKey);
    document.body.classList.add('modal-open');
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.classList.remove('modal-open');
    };
  }, [show, onClose]);

  if (!show) return null;
  return (
    <>
      <div className="modal fade show d-block" tabIndex="-1" role="dialog" onMouseDown={(e) => e.target === e.currentTarget && onClose?.()}>
        <div className={`modal-dialog modal-dialog-centered modal-dialog-scrollable ${size}`} role="document">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title">{title}</h5>
              <button type="button" className="btn-close" aria-label="Close" onClick={onClose} />
            </div>
            <div className="modal-body">{children}</div>
            {footer && <div className="modal-footer">{footer}</div>}
          </div>
        </div>
      </div>
      <div className="modal-backdrop fade show" />
    </>
  );
}

export function ConfirmModal({ show, title = 'Are you sure?', message, confirmLabel = 'Delete', busy, onConfirm, onClose }) {
  return (
    <Modal
      show={show}
      title={title}
      onClose={onClose}
      footer={
        <>
          <button type="button" className="btn btn-light" onClick={onClose}>Cancel</button>
          <button type="button" className="btn btn-danger" disabled={busy} onClick={onConfirm}>
            {busy ? 'Please wait...' : confirmLabel}
          </button>
        </>
      }
    >
      <p className="mb-0">{message}</p>
    </Modal>
  );
}

export function Loader({ label = 'Loading...' }) {
  return (
    <div className="d-flex align-items-center justify-content-center py-5 text-muted gap-2">
      <div className="spinner-border spinner-border-sm text-primary" role="status" />
      <span>{label}</span>
    </div>
  );
}

export function ErrorState({ message, onRetry }) {
  return (
    <div className="alert alert-danger d-flex justify-content-between align-items-center mb-0">
      <span>{message}</span>
      {onRetry && <button type="button" className="btn btn-sm btn-outline-danger" onClick={onRetry}>Retry</button>}
    </div>
  );
}

export function EmptyState({ icon = 'dashboard', message }) {
  return (
    <div className="text-center text-muted py-5">
      <Icon name={icon} size={36} className="mb-2 opacity-50" />
      <p className="mb-0">{message}</p>
    </div>
  );
}

export function Pagination({ meta, onPage }) {
  if (!meta || meta.last_page <= 1) return null;
  const { current_page: page, last_page: last, total, from, to } = meta;
  const pages = [];
  for (let p = Math.max(1, page - 2); p <= Math.min(last, page + 2); p++) pages.push(p);

  return (
    <div className="d-flex justify-content-between align-items-center flex-wrap gap-2 mt-3">
      <small className="text-muted">Showing {from}-{to} of {total}</small>
      <ul className="pagination mb-0">
        <li className={`page-item ${page === 1 ? 'disabled' : ''}`}>
          <button type="button" className="page-link" onClick={() => onPage(page - 1)}>Previous</button>
        </li>
        {pages.map((p) => (
          <li key={p} className={`page-item ${p === page ? 'active' : ''}`}>
            <button type="button" className="page-link" onClick={() => onPage(p)}>{p}</button>
          </li>
        ))}
        <li className={`page-item ${page === last ? 'disabled' : ''}`}>
          <button type="button" className="page-link" onClick={() => onPage(page + 1)}>Next</button>
        </li>
      </ul>
    </div>
  );
}

export function TierBadge({ tier }) {
  if (!tier) return null;
  return (
    <span className="badge rounded-pill fw-semibold" style={TIER_STYLE[tier]}>
      {titleCase(tier)}
    </span>
  );
}

const STATUS_TONE = {
  active: 'success',
  inactive: 'secondary',
  pending: 'warning',
  expired: 'secondary',
  cancelled: 'danger',
  captured: 'success',
  assigned: 'info',
  created: 'warning',
  failed: 'danger',
  published: 'success',
  draft: 'secondary',
};

export function StatusBadge({ status }) {
  return <span className={`badge bg-soft-${STATUS_TONE[status] || 'secondary'} text-${STATUS_TONE[status] || 'secondary'}`}>{titleCase(status)}</span>;
}

export function Field({ label, error, children, hint, required, className = 'mb-3' }) {
  const generatedId = useId();
  const canLink = isValidElement(children) && ['input', 'select', 'textarea'].includes(children.type);
  const id = canLink ? children.props.id || generatedId : undefined;

  return (
    <div className={`form-group ${className}`}>
      {label && (
        <label className="form-label" htmlFor={id}>
          {label} {required && <span className="text-danger">*</span>}
        </label>
      )}
      {canLink ? cloneElement(children, { id, 'aria-invalid': error ? true : undefined }) : children}
      {hint && !error && <small className="form-text text-muted">{hint}</small>}
      {error && <div className="invalid-feedback d-block">{error}</div>}
    </div>
  );
}

export function SubmitButton({ busy, children, className = 'btn btn-primary' }) {
  return (
    <button type="submit" className={className} disabled={busy}>
      {busy && <span className="spinner-border spinner-border-sm me-2" role="status" />}
      {children}
    </button>
  );
}
