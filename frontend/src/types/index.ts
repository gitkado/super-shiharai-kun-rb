export interface Account {
  id: number
  email: string
  status: string
}

export interface AuthResponse {
  jwt: string
  account: Account
}

export interface Invoice {
  id: number
  user_id: number
  issue_date: string
  payment_amount: string
  fee: string
  fee_rate: string
  tax_amount: string
  tax_rate: string
  total_amount: string
  payment_due_date: string
  created_at: string
  updated_at: string
}

export interface InvoicesResponse {
  invoices: Invoice[]
}

export interface ApiError {
  error: {
    code: string
    message: string
    trace_id: string
  }
}
