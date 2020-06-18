type Vehicle = {
  id: string
  name: string
  model: Model
  loaner: boolean
  modelModuleIds: string[]
  modelUpgradeIds: string[]
  paint: ModelPaint
}

type VehicleForm = {
  name: string
  purchased: boolean
  flagship: boolean
  public: boolean
  saleNotify: boolean
  nameVisible: boolean
  hangarGroupIds: string[]
  modelPaintId: string
}

type VehiclesFilter = {
  modelNameCont: string
}

interface VehicleParams extends CollectionParams {
  filters: VehiclesFilter
}
