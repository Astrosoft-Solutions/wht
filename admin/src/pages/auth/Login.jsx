import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { errorMessage } from '../../api/client';
import { useAuth } from '../../auth/AuthContext';
import { SubmitButton } from '../../components/ui';
import AuthShell from './AuthShell';

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [form, setForm] = useState({ login: '', password: '' });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setError('');
    try {
      const user = await login(form.login.trim(), form.password);
      const home = user.role === 'superadmin' ? '/dashboard' : '/coach';
      const from = location.state?.from;
      const allowed = from && (user.role === 'superadmin' ? !from.startsWith('/coach') : from.startsWith('/coach'));
      navigate(allowed ? from : home, { replace: true });
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell title="Sign In" subtitle="Superadmins and coaches sign in here.">
      <form onSubmit={submit} noValidate>
        {error && <div className="alert alert-danger py-2">{error}</div>}
        <div className="form-group">
          <label htmlFor="login" className="form-label">Email or Mobile</label>
          <input
            id="login"
            className="form-control"
            autoComplete="username"
            value={form.login}
            onChange={(e) => setForm({ ...form, login: e.target.value })}
            required
          />
        </div>
        <div className="form-group">
          <label htmlFor="password" className="form-label">Password</label>
          <input
            id="password"
            type="password"
            className="form-control"
            autoComplete="current-password"
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            required
          />
        </div>
        <div className="d-flex justify-content-end mb-3">
          <Link to="/forgot-password">Forgot Password?</Link>
        </div>
        <div className="d-flex justify-content-center">
          <SubmitButton busy={busy}>Sign In</SubmitButton>
        </div>
        <p className="mt-3 text-center text-muted small">
          New coaches can sign up in the WellnessHabitTrack mobile app.
        </p>
      </form>
    </AuthShell>
  );
}
