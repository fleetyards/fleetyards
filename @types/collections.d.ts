type Pagination = {
  currentPage: number
  totalPages: number
}

type CollectionParams = {
  page?: number
}

interface ModelParams extends CollectionParams {
  filters: ModelsFilter
}

interface VehicleParams extends CollectionParams {
  filters: VehiclesFilter
}
