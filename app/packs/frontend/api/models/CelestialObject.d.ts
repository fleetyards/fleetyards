type CelestialObject = {
  id: string
  slug: string
  name: string
}

type CelestialObjectsFilter = {
  nameCont: string
}

interface CelestialObjectParams extends CollectionParams {
  filters: CelestialObjectsFilter
}
