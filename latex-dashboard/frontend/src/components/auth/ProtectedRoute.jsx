// src/components/auth/ProtectedRoute.jsx

import { Navigate } from 'react-router-dom'
import { ROUTE_ROLES } from '../../constants/roles'

const ProtectedRoute = ({ allowedRoles, children }) => {

  const token  = localStorage.getItem('token')
  const role   = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')

  // ── Not logged in ───────────────────────────────────────────────────────────
  if (!token || !role || !userId) {
    return <Navigate to="/login" replace />
  }

  // ── Role not allowed ────────────────────────────────────────────────────────
  if (allowedRoles && !allowedRoles.includes(role)) {
    return <Navigate to="/unauthorized" replace />
  }

  // ── Allowed ─────────────────────────────────────────────────────────────────
  return children
}

export default ProtectedRoute