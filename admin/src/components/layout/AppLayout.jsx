import { useEffect, useState } from 'react';
import { Link, NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import headerImage from '../../assets/hope-ui/images/dashboard/top-header3.png';
import avatar from '../../assets/hope-ui/images/avatars/01.png';
import { titleCase } from '../../utils/format';
import Icon, { BrandLogo } from '../Icon';
import { usePageTitleState } from './PageTitle';

const ADMIN_MENU = [
  { section: 'Home' },
  { to: '/dashboard', label: 'Dashboard', icon: 'dashboard' },
  { section: 'Coaches & Plans' },
  { to: '/coaches', label: 'Coaches', icon: 'users' },
  { to: '/plans', label: 'Plans', icon: 'crown' },
  { to: '/subscriptions', label: 'Subscriptions', icon: 'card' },
  { to: '/payments', label: 'Payments', icon: 'receipt' },
  { section: 'Content' },
  { to: '/master-habits', label: 'Master Habits', icon: 'habit' },
  { to: '/gallery', label: 'Gallery', icon: 'gallery' },
  { to: '/announcements', label: 'Announcements', icon: 'megaphone' },
  { to: '/settings', label: 'Notification Settings', icon: 'settings' },
];

const COACH_MENU = [
  { section: 'My Account' },
  { to: '/coach', label: 'Dashboard', icon: 'dashboard', end: true },
  { to: '/coach/plans', label: 'Choose Plan', icon: 'crown' },
  { to: '/coach/billing', label: 'Billing', icon: 'receipt' },
  { to: '/coach/profile', label: 'Profile', icon: 'user' },
];

function Sidebar({ menu, mini, onToggle }) {
  return (
    <aside className={`sidebar sidebar-default sidebar-white sidebar-base navs-rounded-all ${mini ? 'sidebar-mini' : ''}`}>
      <div className="sidebar-header d-flex align-items-center justify-content-start">
        <Link to="/" className="navbar-brand">
          <BrandLogo size={30} />
          <h4 className="logo-title ms-2">Wellness</h4>
        </Link>
        <div className="sidebar-toggle" role="button" tabIndex={0} onClick={onToggle}>
          <i className="icon">
            <Icon name="arrowLeft" size={20} />
          </i>
        </div>
      </div>
      <div className="sidebar-body pt-0 data-scrollbar">
        <div className="sidebar-list">
          <ul className="navbar-nav iq-main-menu" id="sidebar-menu">
            {menu.map((item, i) =>
              item.section ? (
                <li key={`s${i}`} className="nav-item static-item">
                  <span className="nav-link static-item disabled">
                    <span className="default-icon">{item.section}</span>
                    <span className="mini-icon">-</span>
                  </span>
                </li>
              ) : (
                <li key={item.to} className="nav-item">
                  <NavLink to={item.to} end={item.end} className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                    <i className="icon">
                      <Icon name={item.icon} />
                    </i>
                    <span className="item-name">{item.label}</span>
                  </NavLink>
                </li>
              ),
            )}
          </ul>
        </div>
      </div>
    </aside>
  );
}

function Navbar({ onToggle }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);

  const signOut = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  return (
    <nav className="nav navbar navbar-expand-lg navbar-light iq-navbar">
      <div className="container-fluid navbar-inner">
        <button type="button" className="btn btn-sm btn-light d-xl-none me-2" onClick={onToggle} aria-label="Toggle menu">
          <Icon name="menu" />
        </button>
        <span className="text-muted d-none d-md-inline">
          {user?.role === 'superadmin' ? 'Superadmin Panel' : `${titleCase(user?.coach_type)} Panel`}
        </span>
        <ul className="navbar-nav ms-auto align-items-center">
          <li className="nav-item dropdown">
            <button
              type="button"
              className="nav-link py-0 d-flex align-items-center btn btn-link text-decoration-none"
              onClick={() => setOpen((v) => !v)}
              onBlur={() => setTimeout(() => setOpen(false), 150)}
            >
              <img src={user?.avatar_url || avatar} alt="User" className="img-fluid avatar avatar-40 avatar-rounded" />
              <div className="caption ms-3 d-none d-md-block text-start">
                <h6 className="mb-0 caption-title">{user?.name}</h6>
                <p className="mb-0 caption-sub-title">{user?.role === 'superadmin' ? 'Super Admin' : titleCase(user?.coach_type)}</p>
              </div>
            </button>
            <ul className={`dropdown-menu dropdown-menu-end ${open ? 'show' : ''}`} style={{ right: 0, left: 'auto' }}>
              {user?.role === 'coach' && (
                <li>
                  <Link className="dropdown-item" to="/coach/profile">Profile</Link>
                </li>
              )}
              <li>
                <button type="button" className="dropdown-item" onMouseDown={signOut}>Logout</button>
              </li>
            </ul>
          </li>
        </ul>
      </div>
    </nav>
  );
}

export default function AppLayout() {
  const { user } = useAuth();
  const { title, subtitle } = usePageTitleState();
  const location = useLocation();
  const [mini, setMini] = useState(() => window.innerWidth < 1200);
  const menu = user?.role === 'superadmin' ? ADMIN_MENU : COACH_MENU;

  useEffect(() => {
    if (window.innerWidth < 1200) setMini(true);
  }, [location.pathname]);

  return (
    <>
      <Sidebar menu={menu} mini={mini} onToggle={() => setMini((v) => !v)} />
      <main className="main-content">
        <div className="position-relative iq-banner">
          <Navbar onToggle={() => setMini((v) => !v)} />
          <div className="iq-navbar-header" style={{ height: 215 }}>
            <div className="container-fluid iq-container">
              <div className="row">
                <div className="col-md-12">
                  <div className="flex-wrap d-flex justify-content-between align-items-center">
                    <div>
                      <h1>{title}</h1>
                      {subtitle && <p>{subtitle}</p>}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="iq-header-img">
              <img src={headerImage} alt="" className="img-fluid w-100 h-100 animated-scaleX" />
            </div>
          </div>
        </div>
        <div className="container-fluid content-inner mt-n5 py-0">
          <Outlet />
        </div>
        <footer className="footer">
          <div className="footer-body">
            <span>WellnessHabitTrack &copy; {new Date().getFullYear()}</span>
            <span className="text-muted">Built on Hope UI</span>
          </div>
        </footer>
      </main>
    </>
  );
}
