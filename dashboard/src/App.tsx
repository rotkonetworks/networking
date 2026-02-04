import { createSignal, createResource, createMemo, For, onCleanup } from 'solid-js'
import { query, queryRange, fmtRate, fmtBytes, fmtNum } from './lib/prometheus'
import { Chart, Sparkline } from './components/Chart'

// Instant queries
const Q = {
  totalBw: 'sum(rate(haproxy_frontend_bytes_in_total{proxy=~"ssl-frontend-v."}[5m]) + rate(haproxy_frontend_bytes_out_total{proxy=~"ssl-frontend-v."}[5m]))',
  v4Bw: 'ip_version:frontend_bandwidth:rate5m{ip_version="v4"}',
  v6Bw: 'ip_version:frontend_bandwidth:rate5m{ip_version="v6"}',
  reqRate: 'sum(rate(haproxy_frontend_http_requests_total{proxy=~"ssl-frontend-v."}[5m]))',
  sessions: 'sum(haproxy_frontend_current_sessions{proxy=~"ssl-frontend-v."})',
  transit: 'uplink_type:bandwidth:rate5m{uplink_type="transit"}',
  ixp: 'uplink_type:bandwidth:rate5m{uplink_type="ixp"}',
  ratio: 'cluster:transit_to_ixp_ratio:rate5m',
  ecosystem: 'ecosystem:haproxy_bandwidth:rate5m',
  ecosystemReq: 'ecosystem:haproxy_requests:rate5m',
  endpoints: 'endpoint:haproxy_bandwidth:rate5m',
  endpointsIn: 'endpoint:haproxy_bytes_in:rate5m',
  endpointsOut: 'endpoint:haproxy_bytes_out:rate5m',
  endpointsReq: 'endpoint:haproxy_requests:rate5m',
  endpointsSess: 'sum by (proxy) (haproxy_backend_current_sessions)',
  endpoints24h: 'sum by (proxy) (increase(haproxy_backend_bytes_in_total[24h]) + increase(haproxy_backend_bytes_out_total[24h]))',
  haproxyV4: 'sum by (instance) (rate(haproxy_frontend_bytes_in_total{proxy="ssl-frontend-v4"}[5m]) + rate(haproxy_frontend_bytes_out_total{proxy="ssl-frontend-v4"}[5m]))',
  haproxyV6: 'sum by (instance) (rate(haproxy_frontend_bytes_in_total{proxy="ssl-frontend-v6"}[5m]) + rate(haproxy_frontend_bytes_out_total{proxy="ssl-frontend-v6"}[5m]))',
  uplinks: 'sum by (provider, uplink_type) (uplink:bandwidth:rate5m)',
}

// Time ranges
const ranges = [
  { label: '1h', seconds: 3600, step: 60 },
  { label: '6h', seconds: 21600, step: 120 },
  { label: '24h', seconds: 86400, step: 300 },
  { label: '7d', seconds: 604800, step: 1800 },
  { label: '30d', seconds: 2592000, step: 7200 },
]

const val = (r: any[], key?: string) => {
  if (!r?.length) return 0
  if (key) {
    const m = r.find(x => x.metric[Object.keys(x.metric)[0]] === key)
    return m ? parseFloat(m.value[1]) : 0
  }
  return parseFloat(r[0].value[1])
}

const all = (r: any[]) => r?.map(x => ({ ...x.metric, value: parseFloat(x.value[1]) })) ?? []

export default function App() {
  const [tick, setTick] = createSignal(0)
  const [rangeIdx, setRangeIdx] = createSignal(2) // default 24h
  const range = () => ranges[rangeIdx()]

  // Auto-refresh
  const interval = setInterval(() => setTick(t => t + 1), 15000)
  onCleanup(() => clearInterval(interval))

  // Time params for range queries
  const timeParams = createMemo(() => {
    tick() // depend on tick for refresh
    const now = Date.now() / 1000
    return { start: now - range().seconds, end: now, step: range().step }
  })

  // Instant metrics
  const [totalBw] = createResource(tick, () => query(Q.totalBw))
  const [v4Bw] = createResource(tick, () => query(Q.v4Bw))
  const [v6Bw] = createResource(tick, () => query(Q.v6Bw))
  const [reqRate] = createResource(tick, () => query(Q.reqRate))
  const [sessions] = createResource(tick, () => query(Q.sessions))
  const [transit] = createResource(tick, () => query(Q.transit))
  const [ixp] = createResource(tick, () => query(Q.ixp))
  const [ratio] = createResource(tick, () => query(Q.ratio))
  const [ecosystem] = createResource(tick, () => query(Q.ecosystem))
  const [ecosystemReq] = createResource(tick, () => query(Q.ecosystemReq))
  const [endpoints] = createResource(tick, () => query(Q.endpoints))
  const [endpointsIn] = createResource(tick, () => query(Q.endpointsIn))
  const [endpointsOut] = createResource(tick, () => query(Q.endpointsOut))
  const [endpointsReq] = createResource(tick, () => query(Q.endpointsReq))
  const [endpointsSess] = createResource(tick, () => query(Q.endpointsSess))
  const [endpoints24h] = createResource(tick, () => query(Q.endpoints24h))
  const [haproxyV4] = createResource(tick, () => query(Q.haproxyV4))
  const [haproxyV6] = createResource(tick, () => query(Q.haproxyV6))
  const [uplinks] = createResource(tick, () => query(Q.uplinks))

  // Historical data for charts
  const [totalBwHist] = createResource(timeParams, p => queryRange(Q.totalBw, p.start, p.end, p.step))
  const [v4BwHist] = createResource(timeParams, p => queryRange(Q.v4Bw, p.start, p.end, p.step))
  const [v6BwHist] = createResource(timeParams, p => queryRange(Q.v6Bw, p.start, p.end, p.step))
  const [reqHist] = createResource(timeParams, p => queryRange(Q.reqRate, p.start, p.end, p.step))
  const [ecosystemHist] = createResource(timeParams, p => queryRange(Q.ecosystem, p.start, p.end, p.step))
  const [transitHist] = createResource(timeParams, p => queryRange(Q.transit, p.start, p.end, p.step))
  const [ixpHist] = createResource(timeParams, p => queryRange(Q.ixp, p.start, p.end, p.step))

  // Sparkline data (1h)
  const [totalSparkline] = createResource(tick, () => queryRange(Q.totalBw, Date.now()/1000 - 3600, Date.now()/1000, 60))

  // Merge endpoint data
  const endpointData = () => {
    const bw = all(endpoints())
    return bw.map(e => ({
      name: e.proxy?.replace('-backend', '') ?? '',
      bw: e.value,
      in: all(endpointsIn()).find(x => x.proxy === e.proxy)?.value ?? 0,
      out: all(endpointsOut()).find(x => x.proxy === e.proxy)?.value ?? 0,
      req: all(endpointsReq()).find(x => x.proxy === e.proxy)?.value ?? 0,
      sess: all(endpointsSess()).find(x => x.proxy === e.proxy)?.value ?? 0,
      h24: all(endpoints24h()).find(x => x.proxy === e.proxy)?.value ?? 0,
    })).sort((a, b) => b.bw - a.bw)
  }

  const ecoData = () => {
    const bw = all(ecosystem())
    const req = all(ecosystemReq())
    return bw.map(e => ({
      name: e.ecosystem,
      bw: e.value,
      req: req.find(x => x.ecosystem === e.ecosystem)?.value ?? 0,
    })).sort((a, b) => b.bw - a.bw)
  }

  const haproxyData = () => {
    const v4 = all(haproxyV4())
    const v6 = all(haproxyV6())
    const instances = [...new Set([...v4.map(x => x.instance), ...v6.map(x => x.instance)])]
    return instances.map(i => ({
      name: i,
      v4: v4.find(x => x.instance === i)?.value ?? 0,
      v6: v6.find(x => x.instance === i)?.value ?? 0,
    }))
  }

  const [filter, setFilter] = createSignal('')
  const filteredEndpoints = () => {
    const f = filter().toLowerCase()
    return f ? endpointData().filter(e => e.name.includes(f)) : endpointData()
  }

  // Chart series builders
  const bwSeries = () => [
    { label: 'Total', color: '#3b82f6', data: totalBwHist()?.[0]?.values ?? [] },
  ]

  const ipSeries = () => [
    { label: 'IPv4', color: '#22c55e', data: v4BwHist()?.[0]?.values ?? [] },
    { label: 'IPv6', color: '#8b5cf6', data: v6BwHist()?.[0]?.values ?? [] },
  ]

  const ecoSeries = () => (ecosystemHist() ?? []).map((s, i) => ({
    label: s.metric.ecosystem,
    color: ['#3b82f6', '#22c55e', '#eab308'][i] ?? '#737373',
    data: s.values,
  }))

  const uplinkSeries = () => [
    { label: 'Transit', color: '#eab308', data: transitHist()?.[0]?.values ?? [] },
    { label: 'IXP', color: '#22c55e', data: ixpHist()?.[0]?.values ?? [] },
  ]

  return (
    <div class="min-h-screen bg-bg text-text p-4 font-sans">
      {/* Header */}
      <div class="flex justify-between items-center mb-4">
        <h1 class="text-lg font-semibold">RPC Traffic</h1>
        <div class="flex items-center gap-4">
          <div class="flex gap-1">
            <For each={ranges}>{(r, i) => (
              <button
                class={`px-2 py-0.5 text-xs rounded ${i() === rangeIdx() ? 'bg-accent text-white' : 'bg-surface text-muted hover:text-text'}`}
                onClick={() => setRangeIdx(i())}
              >
                {r.label}
              </button>
            )}</For>
          </div>
          <span class="text-muted text-xs">{new Date().toLocaleTimeString()}</span>
        </div>
      </div>

      {/* Top Stats */}
      <div class="grid grid-cols-8 gap-2 mb-4">
        <Stat label="Total" value={fmtRate(val(totalBw()))} sparkline={totalSparkline()?.[0]?.values} />
        <Stat label="IPv4" value={fmtRate(val(v4Bw()))} color="#22c55e" />
        <Stat label="IPv6" value={fmtRate(val(v6Bw()))} color="#8b5cf6" />
        <Stat label="Req/s" value={fmtNum(val(reqRate()))} />
        <Stat label="Sessions" value={fmtNum(val(sessions()))} />
        <Stat label="Transit" value={fmtRate(val(transit()))} color="#eab308" />
        <Stat label="IXP" value={fmtRate(val(ixp()))} color="#22c55e" />
        <Stat label="TX/IX" value={val(ratio()).toFixed(2)} warn={val(ratio()) > 1} />
      </div>

      {/* Charts Row */}
      <div class="grid grid-cols-2 gap-4 mb-4">
        <div class="card p-2">
          <div class="text-xs text-muted mb-2">Total Bandwidth</div>
          <Chart series={bwSeries()} height={140} />
        </div>
        <div class="card p-2">
          <div class="text-xs text-muted mb-2">IPv4 vs IPv6</div>
          <Chart series={ipSeries()} height={140} showLegend />
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4 mb-4">
        <div class="card p-2">
          <div class="text-xs text-muted mb-2">By Ecosystem</div>
          <Chart series={ecoSeries()} height={140} showLegend />
        </div>
        <div class="card p-2">
          <div class="text-xs text-muted mb-2">Transit vs IXP</div>
          <Chart series={uplinkSeries()} height={140} showLegend />
        </div>
      </div>

      {/* Tables Row */}
      <div class="grid grid-cols-3 gap-4 mb-4">
        <div class="card">
          <div class="px-2 py-1 border-b border-border text-xs text-muted uppercase">Ecosystem</div>
          <table class="w-full text-sm">
            <thead><tr><th class="th">Name</th><th class="th text-right">BW</th><th class="th text-right">Req/s</th></tr></thead>
            <tbody>
              <For each={ecoData()}>{e => (
                <tr class="border-t border-border/50">
                  <td class="td">{e.name}</td>
                  <td class="td text-right">{fmtRate(e.bw)}</td>
                  <td class="td text-right">{fmtNum(e.req)}</td>
                </tr>
              )}</For>
            </tbody>
          </table>
        </div>

        <div class="card">
          <div class="px-2 py-1 border-b border-border text-xs text-muted uppercase">HAProxy Nodes</div>
          <table class="w-full text-sm">
            <thead><tr><th class="th">Node</th><th class="th text-right">v4</th><th class="th text-right">v6</th><th class="th text-right">Total</th></tr></thead>
            <tbody>
              <For each={haproxyData()}>{h => (
                <tr class="border-t border-border/50">
                  <td class="td">{h.name}</td>
                  <td class="td text-right">{fmtRate(h.v4)}</td>
                  <td class="td text-right">{fmtRate(h.v6)}</td>
                  <td class="td text-right">{fmtRate(h.v4 + h.v6)}</td>
                </tr>
              )}</For>
            </tbody>
          </table>
        </div>

        <div class="card">
          <div class="px-2 py-1 border-b border-border text-xs text-muted uppercase">Uplinks</div>
          <table class="w-full text-sm">
            <thead><tr><th class="th">Provider</th><th class="th">Type</th><th class="th text-right">BW</th></tr></thead>
            <tbody>
              <For each={all(uplinks()).sort((a,b) => b.value - a.value)}>{u => (
                <tr class="border-t border-border/50">
                  <td class="td">{u.provider}</td>
                  <td class="td"><span class={u.uplink_type === 'transit' ? 'text-yellow' : 'text-green'}>{u.uplink_type}</span></td>
                  <td class="td text-right">{fmtRate(u.value)}</td>
                </tr>
              )}</For>
            </tbody>
          </table>
        </div>
      </div>

      {/* Endpoints Table */}
      <div class="card">
        <div class="px-2 py-1 border-b border-border flex justify-between items-center">
          <span class="text-xs text-muted uppercase">Endpoints</span>
          <input
            type="text"
            placeholder="Filter..."
            class="bg-bg border border-border rounded px-2 py-0.5 text-xs w-40"
            value={filter()}
            onInput={e => setFilter(e.currentTarget.value)}
          />
        </div>
        <div class="overflow-auto max-h-80">
          <table class="w-full text-sm">
            <thead class="sticky top-0 bg-surface">
              <tr>
                <th class="th">Endpoint</th>
                <th class="th text-right">In</th>
                <th class="th text-right">Out</th>
                <th class="th text-right">Total</th>
                <th class="th text-right">Req/s</th>
                <th class="th text-right">Sess</th>
                <th class="th text-right">24h</th>
              </tr>
            </thead>
            <tbody>
              <For each={filteredEndpoints()}>{e => (
                <tr class="border-t border-border/50 hover:bg-border/20">
                  <td class="td font-medium">{e.name}</td>
                  <td class="td text-right text-muted">{fmtRate(e.in)}</td>
                  <td class="td text-right text-muted">{fmtRate(e.out)}</td>
                  <td class="td text-right">{fmtRate(e.bw)}</td>
                  <td class="td text-right">{fmtNum(e.req)}</td>
                  <td class="td text-right">{Math.round(e.sess)}</td>
                  <td class="td text-right">{fmtBytes(e.h24)}</td>
                </tr>
              )}</For>
            </tbody>
            <tfoot class="border-t border-border bg-surface/50">
              <tr>
                <td class="td font-medium">Total ({filteredEndpoints().length})</td>
                <td class="td text-right">{fmtRate(filteredEndpoints().reduce((a, e) => a + e.in, 0))}</td>
                <td class="td text-right">{fmtRate(filteredEndpoints().reduce((a, e) => a + e.out, 0))}</td>
                <td class="td text-right font-medium">{fmtRate(filteredEndpoints().reduce((a, e) => a + e.bw, 0))}</td>
                <td class="td text-right">{fmtNum(filteredEndpoints().reduce((a, e) => a + e.req, 0))}</td>
                <td class="td text-right">{Math.round(filteredEndpoints().reduce((a, e) => a + e.sess, 0))}</td>
                <td class="td text-right">{fmtBytes(filteredEndpoints().reduce((a, e) => a + e.h24, 0))}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
    </div>
  )
}

function Stat(props: { label: string; value: string; warn?: boolean; color?: string; sparkline?: [number, string][] }) {
  return (
    <div class="card px-2 py-1">
      <div class="flex justify-between items-center">
        <span class="text-xs text-muted">{props.label}</span>
        {props.sparkline && <Sparkline data={props.sparkline} color={props.color} />}
      </div>
      <div
        class="stat text-lg"
        style={{ color: props.warn ? '#eab308' : props.color }}
      >
        {props.value}
      </div>
    </div>
  )
}
