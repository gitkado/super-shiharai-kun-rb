import 'smarthr-ui/smarthr-ui.css'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { IntlProvider } from 'react-intl'
import { createTheme, ThemeProvider } from 'smarthr-ui'
import { BrowserRouter } from 'react-router-dom'
import App from './App'

const theme = createTheme()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <IntlProvider locale="ja" defaultLocale="ja">
      <ThemeProvider theme={theme}>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </ThemeProvider>
    </IntlProvider>
  </StrictMode>,
)
