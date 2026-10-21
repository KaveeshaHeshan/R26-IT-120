/* eslint-disable react-refresh/only-export-components */
// src/context/FactoryDataContext.jsx
//
// Subscribes ONCE to the Firestore collections the dashboard needs
// (users/, tapping_details/) and shares them, so individual pages don't each
// open their own collection listeners. Mounted inside the authenticated
// dashboard layout only.

import { createContext, useContext, useState, useEffect } from 'react'
import { firestoreDb } from '../firebase/config'
import { collection, onSnapshot } from 'firebase/firestore'
import { toDate } from '../utils/aggregate'

const FactoryDataContext = createContext(null)

const permissionMessage = (err, what) =>
  err.code === 'permission-denied'
    ? `Not authorized to read ${what}.`
    : `Unable to load ${what}.`

export const FactoryDataProvider = ({ children }) => {
  const [users, setUsers] = useState([])
  const [sessions, setSessions] = useState([])
  const [usersLoading, setUsersLoading] = useState(true)
  const [sessionsLoading, setSessionsLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    const unsub = onSnapshot(
      collection(firestoreDb, 'users'),
      (snap) => {
        setUsers(snap.docs.map((d) => ({ ...d.data(), uid: d.id })))
        setUsersLoading(false)
      },
      (err) => {
        console.error('users listener:', err)
        setError(permissionMessage(err, 'user records'))
        setUsers([])
        setUsersLoading(false)
      },
    )
    return () => unsub()
  }, [])

  useEffect(() => {
    const unsub = onSnapshot(
      collection(firestoreDb, 'tapping_details'),
      (snap) => {
        setSessions(
          snap.docs.map((d) => {
            const data = d.data()
            return { id: d.id, ...data, sessionDate: toDate(data.date) || toDate(data.createdAt) }
          }),
        )
        setSessionsLoading(false)
      },
      (err) => {
        console.error('tapping_details listener:', err)
        setError((prev) => prev || permissionMessage(err, 'tapping sessions'))
        setSessions([])
        setSessionsLoading(false)
      },
    )
    return () => unsub()
  }, [])

  return (
    <FactoryDataContext.Provider
      value={{ users, sessions, loading: usersLoading || sessionsLoading, error }}
    >
      {children}
    </FactoryDataContext.Provider>
  )
}

export const useFactoryDataContext = () => {
  const ctx = useContext(FactoryDataContext)
  if (!ctx) throw new Error('useFactoryDataContext must be used within FactoryDataProvider')
  return ctx
}
