import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Button,
  Table,
  Td,
  Th,
  Cluster,
  Loader,
  PageHeading,
  Text,
} from 'smarthr-ui'
import { api } from '../api/client'
import type { Invoice, InvoicesResponse } from '../types'
import { PageLayout } from '../components/PageLayout'
import { ErrorNotification } from '../components/ErrorNotification'

export function Invoices() {
  const [invoices, setInvoices] = useState<Invoice[]>([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api
      .get<InvoicesResponse>('/invoices')
      .then((data) => setInvoices(data.invoices))
      .catch((err) => setError(err instanceof Error ? err.message : '取得に失敗しました'))
      .finally(() => setLoading(false))
  }, [])

  return (
    <PageLayout>
      <Cluster justify="space-between" align="center">
        <PageHeading>請求書一覧</PageHeading>
        <Link to="/invoices/new">
          <Button variant="primary">新規作成</Button>
        </Link>
      </Cluster>

      <ErrorNotification message={error} onClose={() => setError('')} />

      {loading ? (
        <Loader alt="読み込み中" />
      ) : invoices.length === 0 ? (
        <Text>請求書がありません。</Text>
      ) : (
        <Table>
          <thead>
            <tr>
              <Th>ID</Th>
              <Th>発行日</Th>
              <Th align="right">支払金額</Th>
              <Th align="right">手数料</Th>
              <Th align="right">税額</Th>
              <Th align="right">合計</Th>
              <Th>支払期日</Th>
            </tr>
          </thead>
          <tbody>
            {invoices.map((inv) => (
              <tr key={inv.id}>
                <Td>{inv.id}</Td>
                <Td>{inv.issue_date}</Td>
                <Td align="right">{Number(inv.payment_amount).toLocaleString()}円</Td>
                <Td align="right">{Number(inv.fee).toLocaleString()}円</Td>
                <Td align="right">{Number(inv.tax_amount).toLocaleString()}円</Td>
                <Td align="right">{Number(inv.total_amount).toLocaleString()}円</Td>
                <Td>{inv.payment_due_date}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </PageLayout>
  )
}
