import { useQuery } from '@tanstack/react-query';
import { api } from '../../api/client';

export function useSubscription() {
  return useQuery({
    queryKey: ['coach-subscription'],
    queryFn: () => api.get('/subscription').then((r) => r.data),
  });
}
