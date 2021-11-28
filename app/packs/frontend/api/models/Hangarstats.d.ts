type HangarStats = {
  total: number
  classifications: HangarStatsClassification[]
  groups: HangarStatsGroup[]
  metrics: HangarStatsMetrics
}

type HangarStatsClassification = {
  classificationCount: number
  name: string
  label: string
}

type HangarStatsGroup = {
  groupCount: number
  id: string,
  slug: string
}

type HangarStatsMetrics = {
  totalMoney: number
  totalMinCrew: number
  totalMaxCrew: number
  totalCargo: number
}
