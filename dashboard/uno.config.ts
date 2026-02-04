import { defineConfig, presetUno, presetTypography } from 'unocss'

export default defineConfig({
  presets: [presetUno(), presetTypography()],
  theme: {
    colors: {
      bg: '#0a0a0a',
      surface: '#141414',
      border: '#262626',
      text: '#e5e5e5',
      muted: '#737373',
      accent: '#3b82f6',
      green: '#22c55e',
      red: '#ef4444',
      yellow: '#eab308'
    }
  },
  shortcuts: {
    'stat': 'font-mono text-right tabular-nums',
    'th': 'text-left text-muted font-normal px-2 py-1 text-xs uppercase tracking-wide',
    'td': 'px-2 py-1 font-mono text-sm tabular-nums',
    'card': 'bg-surface border border-border rounded',
  }
})
