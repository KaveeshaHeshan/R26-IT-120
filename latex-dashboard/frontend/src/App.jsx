// src/App.jsx

import { Routes, Route, Navigate, Outlet } from 'react-router-dom'

import LoginPage from './pages/LoginPage'
import OverviewPage from './pages/OverviewPage'
import FarmersPage from './pages/FarmersPage'
import FarmerDetailPage from './pages/FarmerDetailPage'
import SupervisorsPage from './pages/SupervisorsPage'
import QualityReportPage from './pages/QualityReportPage'
import UnauthorizedPage from './pages/UnauthorizedPage'
import Navbar from './components/layout/Navbar'
import Sidebar from './components/layout/Sidebar'
import { FactoryDataProvider } from './context/FactoryDataContext'
import { ALL_ROLES } from './constants/roles'

// Auth helpers
const getToken = () => localStorage.getItem('token')
const getRole = () => localStorage.getItem('role')
const getUserId = () => localStorage.getItem('user_id')

// Guarded dashboard shell — one mount for the whole authenticated area
const DashboardLayout = () => {
  const token = getToken()
  const role = getRole()
  const userId = getUserId()

  if (!token || !role || !userId) return <Navigate to="/login" replace />
  if (!ALL_ROLES.includes(role)) return <Navigate to="/unauthorized" replace />

  return (
    <FactoryDataProvider>
      <div className="flex flex-wrap items-stretch min-h-screen bg-ground">
        <Sidebar />
        <div className="flex-[999_1_560px] min-w-0 flex flex-col">
          <Navbar />
          <main className="flex-1 overflow-y-auto">
            <div className="max-w-350 mx-auto px-10 py-8">
              <Outlet />
            </div>
          </main>
        </div>
      </div>
    </FactoryDataProvider>
  )
}

const App = () => {
  const isAuth = Boolean(getToken() && getRole() && getUserId())

  return (
    <Routes>
      <Route path="/login" element={isAuth ? <Navigate to="/overview" replace /> : <LoginPage />} />
      <Route path="/unauthorized" element={<UnauthorizedPage />} />

      <Route path="/" element={<Navigate to={isAuth ? '/overview' : '/login'} replace />} />
      <Route path="/summary" element={<Navigate to="/quality" replace />} />

      <Route element={<DashboardLayout />}>
        <Route path="/overview" element={<OverviewPage />} />
        <Route path="/farmers" element={<FarmersPage />} />
        <Route path="/farmers/:uid" element={<FarmerDetailPage />} />
        <Route path="/supervisors" element={<SupervisorsPage />} />
        <Route path="/quality" element={<QualityReportPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  )
}

export default App
