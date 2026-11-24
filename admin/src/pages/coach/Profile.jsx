import { useState } from 'react';
import { api, errorMessage, fieldErrors } from '../../api/client';
import { useAuth } from '../../auth/AuthContext';
import avatar from '../../assets/hope-ui/images/avatars/01.png';
import { usePageTitle } from '../../components/layout/PageTitle';
import { Card, Field, SubmitButton } from '../../components/ui';
import { useToast } from '../../components/ui/Toast';
import { date, titleCase } from '../../utils/format';

export default function Profile() {
  usePageTitle('Profile', 'Your account details.');
  const { user, setUser } = useAuth();
  const notify = useToast();
  const [form, setForm] = useState({ name: user.name, mobile: user.mobile || '' });
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setErrors({});
    try {
      const { data } = await api.put('/me', { name: form.name, mobile: form.mobile || null });
      setUser(data.data);
      notify('Profile updated');
    } catch (err) {
      setErrors(fieldErrors(err));
      notify(errorMessage(err), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="row g-3">
      <div className="col-lg-4">
        <Card>
          <div className="text-center">
            <img src={user.avatar_url || avatar} alt="" className="avatar avatar-100 avatar-rounded mb-3" />
            <h4 className="mb-1">{user.name}</h4>
            <p className="text-muted mb-1">{titleCase(user.coach_type)}</p>
            <small className="text-muted">Member since {date(user.created_at)}</small>
          </div>
        </Card>
      </div>
      <div className="col-lg-8">
        <Card title="Edit Profile">
          <form onSubmit={submit}>
            <Field label="Full Name" required error={errors.name}>
              <input className="form-control" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
            </Field>
            <Field label="Email" hint="Contact the administrator to change your email.">
              <input className="form-control" value={user.email} disabled />
            </Field>
            <Field label="Mobile" error={errors.mobile}>
              <input className="form-control" value={form.mobile} onChange={(e) => setForm({ ...form, mobile: e.target.value })} />
            </Field>
            <SubmitButton busy={busy}>Save Changes</SubmitButton>
          </form>
        </Card>
      </div>
    </div>
  );
}
