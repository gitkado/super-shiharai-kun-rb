import { useCallback, useSyncExternalStore } from 'react'
import { clearToken, isAuthenticated, setToken } from '../api/client'
import { notifyAuthChange, subscribeAuth } from '../api/authState'

function getSnapshot() {
  return isAuthenticated()
}

export function useAuth() {
  const authenticated = useSyncExternalStore(subscribeAuth, getSnapshot)

  const login = useCallback((token: string) => {
    setToken(token)
    notifyAuthChange()
  }, [])

  const logout = useCallback(() => {
    clearToken()
    notifyAuthChange()
  }, [])

  return { authenticated, login, logout }
}
