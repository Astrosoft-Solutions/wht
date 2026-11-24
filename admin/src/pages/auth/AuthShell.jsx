import { Link } from 'react-router-dom';
import authImage from '../../assets/hope-ui/images/auth/01.png';
import { BrandLogo } from '../../components/Icon';

/** Two-column sign-in layout from Hope UI's auth/sign-in.html. */
export default function AuthShell({ title, subtitle, children }) {
  return (
    <div className="wrapper">
      <section className="login-content">
        <div className="row m-0 align-items-center bg-white vh-100">
          <div className="col-md-6">
            <div className="row justify-content-center">
              <div className="col-md-10 col-lg-8">
                <div className="card card-transparent shadow-none d-flex justify-content-center mb-0 auth-card">
                  <div className="card-body">
                    <Link to="/" className="navbar-brand d-flex align-items-center mb-3 text-decoration-none">
                      <BrandLogo size={34} />
                      <h4 className="logo-title ms-3 mb-0">WellnessHabitTrack</h4>
                    </Link>
                    <h2 className="mb-2 text-center">{title}</h2>
                    <p className="text-center">{subtitle}</p>
                    {children}
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="col-md-6 d-md-block d-none auth-brand-panel p-0 mt-n1 vh-100 overflow-hidden">
            <img src={authImage} className="img-fluid gradient-main animated-scaleX" alt="" />
          </div>
        </div>
      </section>
    </div>
  );
}
