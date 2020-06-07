type HangarMetrics = {
  totalMoney: number
  totalMinCrew: number
  totalMaxCrew: number
  totalCargo: number
}

type ClassificationMetrics = {
  name: string
  label: string
  count: number
}

type HangarGroupMetrics = {
  id: string
  slug: string
  count: number
}

type HangarStats = {
  total: number
  classifications: ClassificationMetrics
  groups: HangarGroupMetrics
  metrics: HangarMetrics
}
