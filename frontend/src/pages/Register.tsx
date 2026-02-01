import { type FormEvent, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  Button,
  FormControl,
  Input,
  Cluster,
  Stack,
  TextLink,
  PageHeading,
} from 'smarthr-ui'
import { api, setToken } from '../api/client'
import type { AuthResponse } from '../types'
import { useAuth } from '../hooks/useAuth'
import { PageLayout } from '../components/PageLayout'
import { ErrorNotification } from '../components/ErrorNotification'

export function Register() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [fieldErrors, setFieldErrors] = useState<{ email?: string; password?: string }>({})
  const navigate = useNavigate()
  const { login } = useAuth()

  const validate = () => {
    const errors: typeof fieldErrors = {}
    if (!email) errors.email = 'メールアドレスを入力してください'
    if (!password) errors.password = 'パスワードを入力してください'
    else if (password.length < 8) errors.password = 'パスワードは8文字以上で入力してください'
    setFieldErrors(errors)
    return Object.keys(errors).length === 0
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError('')
    if (!validate()) return
    setLoading(true)
    try {
      const data = await api.post<AuthResponse>('/auth/register', { email, password })
      setToken(data.jwt)
      login(data.jwt)
      navigate('/invoices')
    } catch (err) {
      setError(err instanceof Error ? err.message : '登録に失敗しました')
    } finally {
      setLoading(false)
    }
  }

  return (
    <PageLayout maxWidth={400}>
      <PageHeading>アカウント登録</PageHeading>
      <ErrorNotification message={error} onClose={() => setError('')} />
      <form onSubmit={handleSubmit}>
        <Stack gap={1.5}>
          <FormControl
            label="メールアドレス"
            errorMessages={fieldErrors.email ? [fieldErrors.email] : undefined}
          >
            <Input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              error={!!fieldErrors.email}
            />
          </FormControl>
          <FormControl
            label="パスワード"
            helpMessage="8文字以上で入力してください"
            errorMessages={fieldErrors.password ? [fieldErrors.password] : undefined}
          >
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              error={!!fieldErrors.password}
            />
          </FormControl>
          <Cluster>
            <Button type="submit" variant="primary" disabled={loading}>
              {loading ? '登録中...' : '登録'}
            </Button>
            <TextLink elementAs={Link} to="/login">
              ログインはこちら
            </TextLink>
          </Cluster>
        </Stack>
      </form>
    </PageLayout>
  )
}
