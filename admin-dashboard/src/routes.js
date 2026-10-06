import { Navigate, useRoutes } from 'react-router-dom';
import DashboardLayout from './layouts/dashboard';
import SimpleLayout from './layouts/simple';
import DriversPage from './pages/DriversPage';
import Page404 from './pages/Page404';
import DashboardAppPage from './pages/DashboardAppPage';
import LoginPage from './pages/LoginPage';
import ReportsPage from './pages/ReportsPage';
import TaxiPage from './pages/TaxiPage';
import MapPage from './pages/MapPage';
import MaintenancePage from './pages/MaintenancePage';
import CustomerPage from './pages/CustomerPage';
import ForgotPasswordPage from './pages/ForgotPasswordPage';
import KoreanAddressPage from './pages/KoreanAddressPage';

export default function Router({ setIsLoading, setSnackBarMessage, toast }) {
  const routes = useRoutes([
    {
      path: '/dashboard',
      element: <DashboardLayout />,
      children: [
        { element: <Navigate to="/dashboard/app" />, index: true },
        { path: 'app', element: <DashboardAppPage /> },
        {
          path: 'drivers',
          element: <DriversPage setIsLoading={setIsLoading} setSnackBarMessage={setSnackBarMessage} />,
        },
        {
          path: 'reports',
          element: <ReportsPage setIsLoading={setIsLoading} setSnackBarMessage={setSnackBarMessage} />,
        },
        {
          path: 'taxi',
          element: <TaxiPage setIsLoading={setIsLoading} setSnackBarMessage={setSnackBarMessage} toast={toast} />,
        },
        {
          path: 'map',
          element: <MapPage setIsLoading={setIsLoading} />,
        },
        {
          path: 'maintenance',
          element: <MaintenancePage setIsLoading={setIsLoading} />,
        },
        {
          path: 'customer',
          element: <CustomerPage setIsLoading={setIsLoading} setSnackBarMessage={setSnackBarMessage} />,
        },
        {
          path: 'address',
          element: <KoreanAddressPage setIsLoading={setIsLoading} />,
        },
      ],
    },
    {
      path: 'login',
      element: <LoginPage />,
    },
    {
      path: 'forgotPassword',
      element: <ForgotPasswordPage />,
    },
    {
      element: <SimpleLayout />,
      children: [
        { element: <Navigate to="/dashboard/app" />, index: true },
        { path: '404', element: <Page404 /> },
        { path: '*', element: <Navigate to="/404" /> },
      ],
    },
    {
      path: '*',
      element: <Navigate to="/404" replace />,
    },
  ]);

  return routes;
}
