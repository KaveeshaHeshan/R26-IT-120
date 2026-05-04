// src/App.jsx

import { Routes, Route, Navigate } from 'react-router-dom'
import { useState, useEffect }     from 'react'

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

// ── Protected Route ───────────────────────────────────────────────────────────
const ProtectedRoute = ({ allowedRoles, children }) => {
  const token  = localStorage.getItem('token')
  const role   = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')

  if (!token || !role || !userId) {
    return <Navigate to="/login" replace />
  }

  if (allowedRoles && !allowedRoles.includes(role)) {
    return <Navigate to="/unauthorized" replace />
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

  const token = localStorage.getItem('token')
  const role  = localStorage.getItem('role')

  return (
    <Routes>

      {/* ── Public Route ───────────────────────────────────────────────────── */}
      <Route
        path="/login"
        element={
          token && role
            ? <Navigate to="/" replace />
            : <LoginPage />
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

      {/* ── Default redirect ───────────────────────────────────────────────── */}
      <Route
        path="*"
        element={
          token
            ? <Navigate to="/" replace />
            : <Navigate to="/login" replace />
        }
      />

    </Routes>
  )
}

export default App