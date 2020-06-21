type Model = {
  id: string
  slug: string
  name: string
  manufacturer: Manufacturer
  fleetchartImage: string
  storeImageSmall: string
  length: number
  hasModules: boolean
  hasUpgrades: boolean
  rsiId: string
  rsiName: string
}

type ModelsFilter = {
  nameCont: string
}

interface ModelParams extends CollectionParams {
  filters: ModelsFilter
}

type ModelLoaner = {
  id: string
}

type ModelModule = {
  id: string
}

type ModelPaint = {
  id: string
  rsiId: string
  rsiName: string
}

type ModelUpgrade = {
  id: string
}
