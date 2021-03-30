type ComponentsFilter = {
  nameCont: string
}

interface ComponentParams extends CollectionParams {
  filters: ComponentsFilter
}

type Component = {
  id: string
}
