import { useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { api, errorMessage } from '../../api/client';
import { SubmitButton } from '../../components/ui';
import AuthShell from './AuthShell';

/** Opened from the password-reset email, for coaches using the app as well as panel users. */
export default function ResetPassword() {
  const [params] = useSearchParams();
  const token = params.get('token') || '';
  const [form, setForm] = useState({ email: params.get('email') || '', password: '', password_confirmation: '' });
  const [error, setError] = useState('');
  const [done, setDone] = useState('');
  const [busy, setBusy] = useState(false);

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    if (form.password !== form.password_confirmation) {
      setError('Passwords do not match.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const { data } = await api.post('/reset-password', { token, ...form });
      setDone(data.message || 'Your password has been reset.');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  if (!token) {
    return (
      <AuthShell title="Reset Password" subtitle="This reset link is incomplete.">
        <div className="alert alert-warning">Open the link from your email again, or request a new one.</div>
        <Link to="/forgot-password">Request a new link</Link>
      </AuthShell>
    );
  }

  return (
    <AuthShell title="Choose a New Password" subtitle="Enter a new password for your account.">
      {done ? (
        <>
          <div className="alert alert-success">{done}</div>
          <p className="text-muted">You can now sign in to the WellnessHabitTrack app or this panel with your new password.</p>
          <Link to="/login" className="btn btn-primary">Go to sign in</Link>
        </>
      ) : (
        <form onSubmit={submit}>
          {error && <div className="alert alert-danger py-2">{error}</div>}
          <div className="form-group">
            <label htmlFor="rp-email" className="form-label">Email</label>
            <input id="rp-email" type="email" className="form-control" value={form.email} onChange={set('email')} required />
          </div>
          <div className="form-group">
            <label htmlFor="rp-password" className="form-label">New password</label>
            <input id="rp-password" type="password" minLength={6} className="form-control" value={form.password} onChange={set('password')} autoComplete="new-password" required />
          </div>
          <div className="form-group">
            <label htmlFor="rp-confirm" className="form-label">Confirm new password</label>
            <input id="rp-confirm" type="password" minLength={6} className="form-control" value={form.password_confirmation} onChange={set('password_confirmation')} autoComplete="new-password" required />
          </div>
          <div className="d-flex justify-content-between align-items-center">
            <Link to="/login">Back to sign in</Link>
            <SubmitButton busy={busy}>Reset Password</SubmitButton>
          </div>
        </form>
      )}
    </AuthShell>
  );
}
