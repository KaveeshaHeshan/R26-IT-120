// src/App.jsx

import { Routes, Route, Navigate } from 'react-router-dom'

import HomePage from './pages/HomePage'
import LoginPage from './pages/LoginPage'
import LiveMonitorPage from './pages/LiveMonitorPage'
import FarmerProfilePage from './pages/FarmerProfilePage'
import AlertsPage from './pages/AlertsPage'
import DailySummaryPage from './pages/DailySummaryPage'
import UnauthorizedPage from './pages/UnauthorizedPage'
import Navbar from './components/layout/Navbar'
import Sidebar from './components/layout/Sidebar'
import { ROLES } from './constants/roles'

// Auth helpers 
const getToken = () => localStorage.getItem('token')
const getRole = () => localStorage.getItem('role')
const getUserId = () => localStorage.getItem('user_id')

//  Protected Route 
const ProtectedRoute = ({ allowedRoles, children }) => {
  const token = getToken()
  const role = getRole()
  const userId = getUserId()

  if (!token || !role || !userId) {
    return <Navigate to="/login" replace />
  }
  if (allowedRoles && !allowedRoles.includes(role)) {
    return <Navigate to="/unauthorized" replace />
  }
  return children
}

// Dashboard Layout 
const DashboardLayout = ({ children }) => (
  <div className="flex min-h-screen bg-white">
    <Sidebar />
    <div className="flex-1 flex flex-col min-h-screen overflow-hidden relative">
      <Navbar />
      
      <main className="flex-1 overflow-y-auto relative z-10">
        <div className="max-w-7xl mx-auto p-4 md:p-6">
          {children}
        </div>
      </main>
    </div>
  </div>
)

// ── App ───────────────────────────────────────────────────────────────────────
const App = () => {
  const token = getToken()
  const role = getRole()
  const userId = getUserId()
  const isAuth = Boolean(token && role && userId)

  return (
    <Routes>

      {/* Login */}
      <Route
        path="/login"
        element={
          isAuth
            ? <Navigate to="/dashboard" replace />
            : <LoginPage />
        }
      />

      {/* Unauthorized */}
      <Route
        path="/unauthorized"
        element={<UnauthorizedPage />}
      />

      {/* Home Page */}
      <Route
        path="/"
        element={<HomePage />}
      />

      {/* Live Monitor / Dashboard */}
      <Route
        path="/dashboard"
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