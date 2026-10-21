// src/hooks/useTappingDetails.js
//
// Firestore `tapping_details/` — one doc per latex collection session, written
// by the mobile app. `userId` joins to users/{uid}. Backed by
// FactoryDataProvider (one shared listener). Read-only.

import { useFactoryDataContext } from '../context/FactoryDataContext'

const useTappingDetails = () => {
  const { sessions, loading, error } = useFactoryDataContext()
  return { sessions, loading, error }
}

export default useTappingDetails
