import { notifyAuthChange } from './authState'

const API_BASE = '/api/v1'

function getToken(): string | null {
  return localStorage.getItem('jwt')
}

export function setToken(token: string): void {
  localStorage.setItem('jwt', token)
}

export function clearToken(): void {
  localStorage.removeItem('jwt')
}

export function isAuthenticated(): boolean {
  return getToken() !== null
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken()
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...((options.headers as Record<string, string>) ?? {}),
  }
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers })

  if (res.status === 401) {
    clearToken()
    notifyAuthChange()
    const body = await res.json().catch(() => null)
    const message = body?.error?.message ?? 'セッションが切れました。再度ログインしてください。'
    throw new Error(message)
  }

  if (!res.ok) {
    const body = await res.json().catch(() => null)
    const message = body?.error?.message ?? `Request failed: ${res.status}`
    throw new Error(message)
  }

  return res.json()
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body: unknown) =>
    request<T>(path, { method: 'POST', body: JSON.stringify(body) }),
}
