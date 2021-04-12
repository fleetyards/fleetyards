type AdminModelPaint = {
  id: string
}

type AdminModelPaintFilter = {
  nameCont: string
}

interface AdminModelPaintParams extends CollectionParams {
  filters: AdminModelPaintFilter
}
