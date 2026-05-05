// src/App.jsx

import { Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { useState } from 'react'

// ── Pages ─────────────────────────────────────────────────────────────────────
import LoginPage         from './pages/LoginPage'
import LiveMonitorPage   from './pages/LiveMonitorPage'
import FarmerProfilePage from './pages/FarmerProfilePage'
import AlertsPage        from './pages/AlertsPage'
import DailySummaryPage  from './pages/DailySummaryPage'
import UnauthorizedPage  from './pages/UnauthorizedPage'

// ── Layout ────────────────────────────────────────────────────────────────────
import Navbar  from './components/layout/Navbar'
import Sidebar from './components/layout/Sidebar'

// ── Constants ─────────────────────────────────────────────────────────────────
import { ROLES } from './constants/roles'

// ── Auth Helper ───────────────────────────────────────────────────────────────
const getAuth = () => ({
  token:  localStorage.getItem('token'),
  role:   localStorage.getItem('role'),
  userId: localStorage.getItem('user_id'),
})

const isAuthenticated = () => {
  const { token, role, userId } = getAuth()
  return Boolean(token && role && userId)
}

// ── Protected Route ───────────────────────────────────────────────────────────
const ProtectedRoute = ({ allowedRoles, children }) => {
  const location = useLocation()
  const { token, role, userId } = getAuth()

  if (!token || !role || !userId) {
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  if (allowedRoles && !allowedRoles.includes(role)) {
    return <Navigate to="/unauthorized" replace />
  }

  return children
}

// ── Public Only Route (redirects authenticated users away from /login) ────────
const PublicOnlyRoute = ({ children }) => {
  const authenticated = isAuthenticated()

  if (authenticated) {
    return <Navigate to="/" replace />
  }

  return children
}

// ── Dashboard Layout ──────────────────────────────────────────────────────────
const DashboardLayout = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(true)

  return (
    <div className="flex flex-col min-h-screen">

      {/* Navbar */}
      <Navbar />

      {/* Body */}
      <div className="flex flex-1 overflow-hidden">

        {/* Sidebar */}
        <Sidebar />

        {/* Main content */}
        <main className="flex-1 overflow-y-auto bg-[#F4F6F9]">
          {children}
        </main>

      </div>
    </div>
  )
}

// ── App ───────────────────────────────────────────────────────────────────────
const App = () => {
  return (
    <Routes>

      {/* ── Login (public) ─────────────────────────────────────────────────── */}
      <Route
        path="/login"
        element={
          <PublicOnlyRoute>
            <LoginPage />
          </PublicOnlyRoute>
        }
      />

      {/* ── Unauthorized ───────────────────────────────────────────────────── */}
      <Route
        path="/unauthorized"
        element={<UnauthorizedPage />}
      />

      {/* ── Live Monitor ───────────────────────────────────────────────────── */}
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

      {/* ── Farmer Profile ─────────────────────────────────────────────────── */}
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

      {/* ── Alerts ─────────────────────────────────────────────────────────── */}
      <Route
        path="/alerts"
        element={
          <ProtectedRoute
            allowedRoles={[
              ROLES.MANAGER,
              ROLES.QA_OFFICER,
              ROLES.ADMIN
            ]}
          >
            <DashboardLayout>
              <AlertsPage />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* ── Daily Summary ──────────────────────────────────────────────────── */}
      <Route
        path="/summary"
        element={
          <ProtectedRoute
            allowedRoles={[
              ROLES.MANAGER,
              ROLES.QA_OFFICER,
              ROLES.ADMIN
            ]}
          >
            <DashboardLayout>
              <DailySummaryPage />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* ── Catch-all ──────────────────────────────────────────────────────── */}
      <Route
        path="*"
        element={<Navigate to="/" replace />}
      />

    </Routes>
  )
}

export default App