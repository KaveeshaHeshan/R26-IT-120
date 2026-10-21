// src/hooks/useUsers.js
//
// Firestore `users/` — farmers + supervisors share this collection, split by
// `role`. Backed by FactoryDataProvider (one shared listener). Read-only.

import { useMemo } from 'react'
import { useFactoryDataContext } from '../context/FactoryDataContext'

const useUsers = () => {
  const { users, loading, error } = useFactoryDataContext()

  const derived = useMemo(() => {
    const farmers = users.filter((u) => u.role === 'farmer')
    const supervisors = users.filter((u) => u.role === 'supervisor')
    const usersById = new Map(users.map((u) => [u.uid, u]))
    return { farmers, supervisors, usersById }
  }, [users])

  return { users, ...derived, loading, error }
}

export default useUsers
