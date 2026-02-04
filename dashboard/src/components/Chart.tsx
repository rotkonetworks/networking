import { createEffect, onCleanup } from 'solid-js'

type Series = { label: string; color: string; data: [number, string][] }

export function Chart(props: {
  series: Series[]
  height?: number
  showLegend?: boolean
}) {
  let canvas: HTMLCanvasElement
  let container: HTMLDivElement

  createEffect(() => {
    if (!props.series.length || !props.series[0].data.length) return

    const ctx = canvas.getContext('2d')!
    const dpr = window.devicePixelRatio || 1
    const rect = container.getBoundingClientRect()
    const w = rect.width
    const h = props.height ?? 120

    canvas.width = w * dpr
    canvas.height = h * dpr
    canvas.style.width = w + 'px'
    canvas.style.height = h + 'px'
    ctx.scale(dpr, dpr)

    // Find global min/max
    let minT = Infinity, maxT = -Infinity, maxV = 0
    for (const s of props.series) {
      for (const [t, v] of s.data) {
        minT = Math.min(minT, t)
        maxT = Math.max(maxT, t)
        maxV = Math.max(maxV, parseFloat(v))
      }
    }
    if (maxV === 0) maxV = 1

    const pad = { t: 10, r: 10, b: 20, l: 50 }
    const plotW = w - pad.l - pad.r
    const plotH = h - pad.t - pad.b

    // Clear
    ctx.fillStyle = '#141414'
    ctx.fillRect(0, 0, w, h)

    // Grid lines
    ctx.strokeStyle = '#262626'
    ctx.lineWidth = 1
    for (let i = 0; i <= 4; i++) {
      const y = pad.t + (plotH / 4) * i
      ctx.beginPath()
      ctx.moveTo(pad.l, y)
      ctx.lineTo(w - pad.r, y)
      ctx.stroke()
    }

    // Y axis labels
    ctx.fillStyle = '#737373'
    ctx.font = '10px monospace'
    ctx.textAlign = 'right'
    for (let i = 0; i <= 4; i++) {
      const y = pad.t + (plotH / 4) * i
      const val = maxV * (1 - i / 4)
      ctx.fillText(fmtAxis(val), pad.l - 5, y + 3)
    }

    // X axis labels
    ctx.textAlign = 'center'
    const tRange = maxT - minT
    for (let i = 0; i <= 4; i++) {
      const x = pad.l + (plotW / 4) * i
      const t = minT + (tRange / 4) * i
      const d = new Date(t * 1000)
      ctx.fillText(d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }), x, h - 5)
    }

    // Draw series
    for (const s of props.series) {
      ctx.strokeStyle = s.color
      ctx.lineWidth = 1.5
      ctx.beginPath()

      for (let i = 0; i < s.data.length; i++) {
        const [t, v] = s.data[i]
        const x = pad.l + ((t - minT) / tRange) * plotW
        const y = pad.t + plotH - (parseFloat(v) / maxV) * plotH
        i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
      }
      ctx.stroke()

      // Fill under curve
      ctx.lineTo(pad.l + plotW, pad.t + plotH)
      ctx.lineTo(pad.l, pad.t + plotH)
      ctx.closePath()
      ctx.fillStyle = s.color + '20'
      ctx.fill()
    }
  })

  // Resize handler
  const resize = () => canvas && canvas.dispatchEvent(new Event('resize'))
  window.addEventListener('resize', resize)
  onCleanup(() => window.removeEventListener('resize', resize))

  return (
    <div ref={container!} class="w-full">
      <canvas ref={canvas!} />
      {props.showLegend && (
        <div class="flex gap-4 mt-1 text-xs">
          {props.series.map(s => (
            <div class="flex items-center gap-1">
              <div class="w-3 h-0.5" style={{ background: s.color }} />
              <span class="text-muted">{s.label}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function fmtAxis(n: number): string {
  if (n === 0) return '0'
  if (n >= 1e9) return (n / 1e9).toFixed(1) + 'G'
  if (n >= 1e6) return (n / 1e6).toFixed(1) + 'M'
  if (n >= 1e3) return (n / 1e3).toFixed(1) + 'K'
  return n.toFixed(0)
}

// Mini sparkline for stat cards
export function Sparkline(props: { data: [number, string][]; color?: string }) {
  let canvas: HTMLCanvasElement

  createEffect(() => {
    if (!props.data?.length) return
    const ctx = canvas.getContext('2d')!
    const w = canvas.width, h = canvas.height
    const values = props.data.map(d => parseFloat(d[1]))
    const max = Math.max(...values) || 1

    ctx.clearRect(0, 0, w, h)
    ctx.strokeStyle = props.color ?? '#3b82f6'
    ctx.lineWidth = 1
    ctx.beginPath()

    for (let i = 0; i < values.length; i++) {
      const x = (i / (values.length - 1)) * w
      const y = h - (values[i] / max) * h * 0.9
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
    }
    ctx.stroke()
  })

  return <canvas ref={canvas!} width={60} height={20} class="opacity-60" />
}
