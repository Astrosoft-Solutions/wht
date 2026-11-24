import { useState } from 'react';
import { Link } from 'react-router-dom';
import { api, errorMessage } from '../../api/client';
import { SubmitButton } from '../../components/ui';
import AuthShell from './AuthShell';

export default function ForgotPassword() {
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setError('');
    try {
      const { data } = await api.post('/forgot-password', { email: email.trim() });
      setMessage(data.message);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell title="Reset Password" subtitle="Enter your email and we'll send you a reset link.">
      <form onSubmit={submit}>
        {error && <div className="alert alert-danger py-2">{error}</div>}
        {message && <div className="alert alert-success py-2">{message}</div>}
        <div className="form-group">
          <label htmlFor="email" className="form-label">Email</label>
          <input id="email" type="email" className="form-control" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </div>
        <div className="d-flex justify-content-between align-items-center">
          <Link to="/login">Back to sign in</Link>
          <SubmitButton busy={busy}>Send Reset Link</SubmitButton>
        </div>
      </form>
    </AuthShell>
  );
}
