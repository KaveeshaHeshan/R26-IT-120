// src/hooks/useFactoryData.js
//
// Composes users/ + tapping_details/ into the joined dataset the Overview and
// Farmers pages consume. Each session is enriched with its farmer's profile
// fields via the userId -> users/{uid} join.

import { useMemo } from 'react'
import useUsers from './useUsers'
import useTappingDetails from './useTappingDetails'
import { farmerActivity, uniqueSorted } from '../utils/aggregate'

const useFactoryData = () => {
  const { users, farmers, supervisors, usersById, loading: usersLoading, error: usersError } = useUsers()
  const { sessions, loading: sessionsLoading, error: sessionsError } = useTappingDetails()

  const joinedSessions = useMemo(
    () =>
      sessions
        .map((s) => {
          const owner = usersById.get(s.userId)
          if (!owner) return null
          return {
            ...s,
            farmerName: owner.name || '',
            district: owner.district || '',
            address: owner.address || '',
            modelFarmerId: owner.modelFarmerId || '',
            ownerRole: owner.role || '',
          }
        })
        .filter(Boolean),
    [sessions, usersById],
  )

  const activityByFarmer = useMemo(() => farmerActivity(joinedSessions), [joinedSessions])

  const districts = useMemo(
    () => uniqueSorted(farmers.map((f) => f.district)),
    [farmers],
  )

  return {
    users,
    farmers,
    supervisors,
    usersById,
    sessions,
    joinedSessions,
    activityByFarmer,
    districts,
    loading: usersLoading || sessionsLoading,
    error: usersError || sessionsError,
  }
}

export default useFactoryData
