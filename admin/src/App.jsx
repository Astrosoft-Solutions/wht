import { createBrowserRouter, Navigate, Outlet, RouterProvider, useLocation } from 'react-router-dom';
import { useAuth } from './auth/AuthContext';
import AppLayout from './components/layout/AppLayout';
import { Loader } from './components/ui';
import Login from './pages/auth/Login';
import ForgotPassword from './pages/auth/ForgotPassword';
import ResetPassword from './pages/auth/ResetPassword';
import Dashboard from './pages/admin/Dashboard';
import Coaches from './pages/admin/Coaches';
import CoachDetail from './pages/admin/CoachDetail';
import Plans from './pages/admin/Plans';
import Subscriptions from './pages/admin/Subscriptions';
import Payments from './pages/admin/Payments';
import MasterHabits from './pages/admin/MasterHabits';
import Gallery from './pages/admin/Gallery';
import Announcements from './pages/admin/Announcements';
import Settings from './pages/admin/Settings';
import CoachDashboard from './pages/coach/CoachDashboard';
import ChoosePlan from './pages/coach/ChoosePlan';
import Billing from './pages/coach/Billing';
import Profile from './pages/coach/Profile';

function homeFor(user) {
  return user?.role === 'superadmin' ? '/dashboard' : '/coach';
}

function RequireRole({ role }) {
  const { user, loading } = useAuth();
  const location = useLocation();

  if (loading) return <Loader label="Checking your session..." />;
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  if (user.role !== role) return <Navigate to={homeFor(user)} replace />;
  return <Outlet />;
}

function GuestOnly() {
  const { user, loading } = useAuth();
  if (loading) return <Loader label="Checking your session..." />;
  return user ? <Navigate to={homeFor(user)} replace /> : <Outlet />;
}

function Home() {
  const { user, loading } = useAuth();
  if (loading) return <Loader label="Checking your session..." />;
  return <Navigate to={user ? homeFor(user) : '/login'} replace />;
}

const router = createBrowserRouter(
  [
    { path: '/', element: <Home /> },
    { path: '/reset-password', element: <ResetPassword /> },
    {
      element: <GuestOnly />,
      children: [
        { path: '/login', element: <Login /> },
        { path: '/forgot-password', element: <ForgotPassword /> },
      ],
    },
    {
      element: <RequireRole role="superadmin" />,
      children: [
        {
          element: <AppLayout />,
          children: [
            { path: '/dashboard', element: <Dashboard /> },
            { path: '/coaches', element: <Coaches /> },
            { path: '/coaches/:id', element: <CoachDetail /> },
            { path: '/plans', element: <Plans /> },
            { path: '/subscriptions', element: <Subscriptions /> },
            { path: '/payments', element: <Payments /> },
            { path: '/master-habits', element: <MasterHabits /> },
            { path: '/gallery', element: <Gallery /> },
            { path: '/announcements', element: <Announcements /> },
            { path: '/settings', element: <Settings /> },
          ],
        },
      ],
    },
    {
      element: <RequireRole role="coach" />,
      children: [
        {
          element: <AppLayout />,
          children: [
            { path: '/coach', element: <CoachDashboard /> },
            { path: '/coach/plans', element: <ChoosePlan /> },
            { path: '/coach/billing', element: <Billing /> },
            { path: '/coach/profile', element: <Profile /> },
          ],
        },
      ],
    },
    { path: '*', element: <Home /> },
  ],
  { basename: '/admin' },
);

export default function App() {
  return <RouterProvider router={router} />;
}
