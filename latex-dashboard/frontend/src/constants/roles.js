// src/constants/roles.js

// ── User Roles ────────────────────────────────────────────────────────────────
export const ROLES = {
  MANAGER:    'manager',
  QA_OFFICER: 'qa_officer',
  ADMIN:      'admin',
}

// ── Role Labels ───────────────────────────────────────────────────────────────
export const ROLE_LABELS = {
  manager:    'Factory Manager',
  qa_officer: 'QA Officer',
  admin:      'System Admin',
}

// ── Role Permissions ──────────────────────────────────────────────────────────
export const ROLE_PERMISSIONS = {
  manager: [
    'daily_summary',
  ],
  qa_officer: [
    'daily_summary',
  ],
  admin: [
    'daily_summary',
    'user_management',
  ],
}

// ── Check Permission ──────────────────────────────────────────────────────────
export const hasPermission = (role, permission) => {
  return ROLE_PERMISSIONS[role]?.includes(permission) || false
}

// ── Get Role Label ────────────────────────────────────────────────────────────
export const getRoleLabel = (role) => {
  return ROLE_LABELS[role] || role
}

// ── Allowed Roles per Route ───────────────────────────────────────────────────
export const ROUTE_ROLES = {
  '/':              ['manager', 'admin'],
  '/summary':       ['manager', 'qa_officer', 'admin'],
  '/unauthorized':  ['manager', 'qa_officer', 'admin'],
}