import axios from 'axios';

export const TOKEN_KEY = 'wht_admin_token';

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api/v1',
  headers: { Accept: 'application/json' },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 && localStorage.getItem(TOKEN_KEY)) {
      localStorage.removeItem(TOKEN_KEY);
      window.dispatchEvent(new Event('auth:expired'));
    }
    return Promise.reject(error);
  },
);

/** First readable message from a Laravel error response. */
export function errorMessage(error) {
  const data = error?.response?.data;
  if (data?.errors) {
    const first = Object.values(data.errors)[0];
    if (Array.isArray(first) && first.length) return first[0];
  }
  if (data?.message) return data.message;
  if (error?.code === 'ERR_NETWORK') return 'Cannot reach the server. Is the API running?';
  return error?.message || 'Something went wrong.';
}

/** Laravel validation errors as { field: 'message' }. */
export function fieldErrors(error) {
  const errors = error?.response?.data?.errors || {};
  return Object.fromEntries(Object.entries(errors).map(([key, messages]) => [key, messages[0]]));
}
