import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import './assets/hope-ui/css/core/libs.min.css';
import './assets/hope-ui/css/hope-ui.min.css';
import './assets/hope-ui/css/custom.min.css';
import './styles/app.css';
import App from './App';
import { AuthProvider } from './auth/AuthContext';
import { ToastProvider } from './components/ui/Toast';
import { PageTitleProvider } from './components/layout/PageTitle';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 1, refetchOnWindowFocus: false, staleTime: 30_000 },
  },
});

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ToastProvider>
          <PageTitleProvider>
            <App />
          </PageTitleProvider>
        </ToastProvider>
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>,
);
