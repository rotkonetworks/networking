const BASE = '/api/v1'

type Metric = { metric: Record<string, string>; value: [number, string] }
type QueryResult = { status: string; data: { resultType: string; result: Metric[] } }

export async function query(expr: string): Promise<Metric[]> {
  const res = await fetch(`${BASE}/query?query=${encodeURIComponent(expr)}`)
  const json: QueryResult = await res.json()
  return json.data?.result ?? []
}

export async function queryRange(
  expr: string,
  start: number,
  end: number,
  step: number
): Promise<{ metric: Record<string, string>; values: [number, string][] }[]> {
  const params = new URLSearchParams({
    query: expr,
    start: start.toString(),
    end: end.toString(),
    step: step.toString()
  })
  const res = await fetch(`${BASE}/query_range?${params}`)
  const json = await res.json()
  return json.data?.result ?? []
}

// Format bytes to human readable
export function fmtBytes(n: number): string {
  if (n === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(n) / Math.log(k))
  return (n / Math.pow(k, i)).toFixed(2) + ' ' + sizes[i]
}

// Format bytes/sec to human readable rate
export function fmtRate(n: number): string {
  if (n === 0) return '0 B/s'
  const k = 1024
  const sizes = ['B/s', 'KB/s', 'MB/s', 'GB/s']
  const i = Math.floor(Math.log(n) / Math.log(k))
  return (n / Math.pow(k, i)).toFixed(2) + ' ' + sizes[i]
}

// Format number with SI suffix
export function fmtNum(n: number): string {
  if (n < 1000) return n.toFixed(1)
  if (n < 1e6) return (n / 1e3).toFixed(1) + 'k'
  if (n < 1e9) return (n / 1e6).toFixed(1) + 'M'
  return (n / 1e9).toFixed(1) + 'G'
}
