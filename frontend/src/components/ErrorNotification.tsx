import { NotificationBar } from 'smarthr-ui'

type Props = {
  message: string
  onClose?: () => void
}

export function ErrorNotification({ message, onClose }: Props) {
  if (!message) return null

  return (
    <NotificationBar type="error" bold onClose={onClose} role="alert">
      {message}
    </NotificationBar>
  )
}
