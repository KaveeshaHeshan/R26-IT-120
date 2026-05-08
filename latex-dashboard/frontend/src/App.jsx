// src/App.jsx

import { Routes, Route, Navigate } from 'react-router-dom'

import LoginPage         from './pages/LoginPage'
import LiveMonitorPage   from './pages/LiveMonitorPage'
import FarmerProfilePage from './pages/FarmerProfilePage'
import AlertsPage        from './pages/AlertsPage'
import DailySummaryPage  from './pages/DailySummaryPage'
import UnauthorizedPage  from './pages/UnauthorizedPage'
import Navbar            from './components/layout/Navbar'
import Sidebar           from './components/layout/Sidebar'
import { ROLES }         from './constants/roles'

// ── Auth helpers ──────────────────────────────────────────────────────────────
const getToken  = () => localStorage.getItem('token')
const getRole   = () => localStorage.getItem('role')
const getUserId = () => localStorage.getItem('user_id')

// ── Protected Route ───────────────────────────────────────────────────────────
const ProtectedRoute = ({ allowedRoles, children }) => {
  const token  = getToken()
  const role   = getRole()
  const userId = getUserId()

  if (!token || !role || !userId) {
    return <Navigate to="/login" replace />
  }
  if (allowedRoles && !allowedRoles.includes(role)) {
    return <Navigate to="/unauthorized" replace />
  }
  return children
}

// ── Dashboard Layout ──────────────────────────────────────────────────────────
const DashboardLayout = ({ children }) => (
  <div className="flex flex-col min-h-screen">
    <Navbar />
    <div className="flex flex-1 overflow-hidden">
      <Sidebar />
      <main className="flex-1 overflow-y-auto bg-[#F4F6F9]">
        {children}
      </main>
    </div>
  </div>
)

// ── App ───────────────────────────────────────────────────────────────────────
const App = () => {
  const token  = getToken()
  const role   = getRole()
  const userId = getUserId()
  const isAuth = Boolean(token && role && userId)

  return (
    <Routes>

      {/* Login */}
      <Route
        path="/login"
        element={
          isAuth
            ? <Navigate to="/" replace />
            : <LoginPage />
        }
      />

      {/* Unauthorized */}
      <Route
        path="/unauthorized"
        element={<UnauthorizedPage />}
      />

      {/* Live Monitor */}
      <Route
        path="/"
        element={
          <ProtectedRoute allowedRoles={[ROLES.MANAGER, ROLES.ADMIN]}>
            <DashboardLayout>
              <LiveMonitorPage />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Farmer Profile */}
      <Route
        path="/farmer"
        element={
          <ProtectedRoute allowedRoles={[ROLES.MANAGER, ROLES.ADMIN]}>
            <DashboardLayout>
              <FarmerProfilePage />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Alerts */}
      <Route
        path="/alerts"
        element={
          <ProtectedRoute allowedRoles={[
            ROLES.MANAGER, ROLES.QA_OFFICER, ROLES.ADMIN
          ]}>
            <DashboardLayout>
              <AlertsPage />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Daily Summary */}
      <Route
        path="/summary"
        element={
          <ProtectedRoute allowedRoles={[
            ROLES.MANAGER, ROLES.QA_OFFICER, ROLES.ADMIN
          ]}>
            <DashboardLayout>
              <DailySummaryPage />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Catch-all */}
      <Route
        path="*"
        element={<Navigate to="/login" replace />}
      />

    </Routes>
  )
}

export default App