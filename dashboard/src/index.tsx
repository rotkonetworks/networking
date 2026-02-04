import { render } from 'solid-js/web'
import App from './App'
import 'virtual:uno.css'
import '@unocss/reset/tailwind.css'

render(() => <App />, document.getElementById('app')!)
