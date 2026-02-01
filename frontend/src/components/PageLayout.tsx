import type { ReactNode } from 'react'
import { Center, Stack } from 'smarthr-ui'

type Props = {
  children: ReactNode
  maxWidth?: number | string
  gap?: number
}

export function PageLayout({ children, maxWidth = 900, gap = 1.5 }: Props) {
  return (
    <Center maxWidth={maxWidth} padding={1.5}>
      <Stack gap={gap} style={{ width: '100%' }}>
        {children}
      </Stack>
    </Center>
  )
}
