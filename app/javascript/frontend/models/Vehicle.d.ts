type Vehicle = {
  id: string
  name: string
  model: Model
  loaner: boolean
  modelModuleIds: string[]
  modelUpgradeIds: string[]
  paint: ModelPaint
}

type VehiclesFilter = {
  modelNameCont: string
}

interface VehicleParams extends CollectionParams {
  filters: VehiclesFilter
}
