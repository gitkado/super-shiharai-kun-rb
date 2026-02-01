const listeners = new Set<() => void>()

export function subscribeAuth(callback: () => void) {
  listeners.add(callback)
  return () => listeners.delete(callback)
}

export function notifyAuthChange() {
  listeners.forEach((l) => l())
}
