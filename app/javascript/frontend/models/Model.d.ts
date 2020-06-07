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
