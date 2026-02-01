import { Routes, Route, Navigate, Outlet, Link, useLocation } from 'react-router-dom'
import { AppNavi, AppNaviAnchor, Header, TextLink } from 'smarthr-ui'
import { useAuth } from './hooks/useAuth'
import logoSvg from './assets/logo.svg'

import { Login } from './pages/Login'
import { Register } from './pages/Register'
import { Invoices } from './pages/Invoices'
import { InvoiceNew } from './pages/InvoiceNew'

function ProtectedRoute() {
  const { authenticated } = useAuth()
  if (!authenticated) {
    return <Navigate to="/login" replace />
  }
  return <Outlet />
}

function AppHeader() {
  const { authenticated, logout } = useAuth()

  return (
    <Header
      logo={<img src={logoSvg} alt="スーパー支払い君" height={28} style={{ verticalAlign: 'middle' }} />}
      tenants={[]}
    >
      {authenticated && (
        <button
          type="button"
          onClick={logout}
          style={{ color: 'white', background: 'none', border: 'none', cursor: 'pointer', fontSize: '14px', padding: 0 }}
        >
          ログアウト
        </button>
      )}
      {!authenticated && (
        <>
          <TextLink elementAs={Link} to="/login" style={{ color: 'white' }}>ログイン</TextLink>
          <TextLink elementAs={Link} to="/register" style={{ color: 'white' }}>登録</TextLink>
        </>
      )}
    </Header>
  )
}

function AppNavigation() {
  const location = useLocation()
  const { authenticated } = useAuth()

  if (!authenticated) return null

  return (
    <AppNavi label="メニュー">
      <AppNaviAnchor
        elementAs={Link}
        to="/invoices"
        current={location.pathname === '/invoices'}
      >
        請求書一覧
      </AppNaviAnchor>
      <AppNaviAnchor
        elementAs={Link}
        to="/invoices/new"
        current={location.pathname === '/invoices/new'}
      >
        請求書作成
      </AppNaviAnchor>
    </AppNavi>
  )
}

function App() {
  return (
    <>
      <AppHeader />
      <AppNavigation />
      <main>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route element={<ProtectedRoute />}>
            <Route path="/invoices" element={<Invoices />} />
            <Route path="/invoices/new" element={<InvoiceNew />} />
          </Route>
          <Route path="*" element={<Navigate to="/invoices" replace />} />
        </Routes>
      </main>
    </>
  )
}

export default App
