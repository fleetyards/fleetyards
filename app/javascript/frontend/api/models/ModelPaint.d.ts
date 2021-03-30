type ModelPaintsFilter = {
  nameCont: string
}

interface ModelPaintParams extends CollectionParams {
  filters: ModelPaintsFilter
}

type ModelPaint = {
  id: string
  rsiId: string
  rsiName: string
}
