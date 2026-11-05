import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { api, TOKEN_KEY } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(() => Boolean(localStorage.getItem(TOKEN_KEY)));

  const refreshUser = useCallback(async () => {
    const { data } = await api.get('/me');
    setUser(data.data);
    return data.data;
  }, []);

  useEffect(() => {
    if (!localStorage.getItem(TOKEN_KEY)) return;
    refreshUser()
      .catch(() => localStorage.removeItem(TOKEN_KEY))
      .finally(() => setLoading(false));
  }, [refreshUser]);

  useEffect(() => {
    const onExpired = () => setUser(null);
    window.addEventListener('auth:expired', onExpired);
    return () => window.removeEventListener('auth:expired', onExpired);
  }, []);

  const login = useCallback(async (login, password) => {
    const { data } = await api.post('/login', { login, password, device_name: 'admin-panel' });
    localStorage.setItem(TOKEN_KEY, data.token);
    setUser(data.user);
    return data.user;
  }, []);

  const logout = useCallback(async () => {
    try {
      await api.post('/logout');
    } catch {
      // The local session is cleared even if the server call fails.
    }
    localStorage.removeItem(TOKEN_KEY);
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({ user, loading, login, logout, refreshUser, setUser }),
    [user, loading, login, logout, refreshUser],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
