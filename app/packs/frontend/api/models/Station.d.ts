type Station = {
  id: string
}

type StationsFilter = {
  nameCont: string
}

interface StationParams extends CollectionParams {
  filters: StationsFilter
}
