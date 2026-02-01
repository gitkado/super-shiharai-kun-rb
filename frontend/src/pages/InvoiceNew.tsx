import { type FormEvent, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Button,
  FormControl,
  Input,
  Cluster,
  Stack,
  PageHeading,
} from 'smarthr-ui'
import { api } from '../api/client'
import type { Invoice } from '../types'
import { PageLayout } from '../components/PageLayout'
import { ErrorNotification } from '../components/ErrorNotification'

export function InvoiceNew() {
  const [issueDate, setIssueDate] = useState('')
  const [paymentAmount, setPaymentAmount] = useState('')
  const [paymentDueDate, setPaymentDueDate] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [fieldErrors, setFieldErrors] = useState<{
    issueDate?: string
    paymentAmount?: string
    paymentDueDate?: string
  }>({})
  const navigate = useNavigate()

  const validate = () => {
    const errors: typeof fieldErrors = {}
    if (!issueDate) errors.issueDate = '発行日を入力してください'
    if (!paymentAmount) errors.paymentAmount = '支払金額を入力してください'
    else if (Number(paymentAmount) < 1) errors.paymentAmount = '支払金額は1以上で入力してください'
    if (!paymentDueDate) errors.paymentDueDate = '支払期日を入力してください'
    setFieldErrors(errors)
    return Object.keys(errors).length === 0
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError('')
    if (!validate()) return
    setLoading(true)
    try {
      await api.post<Invoice>('/invoices', {
        issue_date: issueDate,
        payment_amount: paymentAmount,
        payment_due_date: paymentDueDate,
      })
      navigate('/invoices')
    } catch (err) {
      setError(err instanceof Error ? err.message : '作成に失敗しました')
    } finally {
      setLoading(false)
    }
  }

  return (
    <PageLayout maxWidth={400}>
      <PageHeading>請求書作成</PageHeading>
      <ErrorNotification message={error} onClose={() => setError('')} />
      <form onSubmit={handleSubmit}>
        <Stack gap={1.5}>
          <FormControl
            label="発行日"
            errorMessages={fieldErrors.issueDate ? [fieldErrors.issueDate] : undefined}
          >
            <Input
              type="date"
              value={issueDate}
              onChange={(e) => setIssueDate(e.target.value)}
              error={!!fieldErrors.issueDate}
            />
          </FormControl>
          <FormControl
            label="支払金額"
            errorMessages={fieldErrors.paymentAmount ? [fieldErrors.paymentAmount] : undefined}
          >
            <Input
              type="number"
              value={paymentAmount}
              onChange={(e) => setPaymentAmount(e.target.value)}
              error={!!fieldErrors.paymentAmount}
            />
          </FormControl>
          <FormControl
            label="支払期日"
            errorMessages={fieldErrors.paymentDueDate ? [fieldErrors.paymentDueDate] : undefined}
          >
            <Input
              type="date"
              value={paymentDueDate}
              onChange={(e) => setPaymentDueDate(e.target.value)}
              error={!!fieldErrors.paymentDueDate}
            />
          </FormControl>
          <Cluster>
            <Button type="submit" variant="primary" disabled={loading}>
              {loading ? '作成中...' : '作成'}
            </Button>
            <Button variant="secondary" onClick={() => navigate('/invoices')}>
              キャンセル
            </Button>
          </Cluster>
        </Stack>
      </form>
    </PageLayout>
  )
}
