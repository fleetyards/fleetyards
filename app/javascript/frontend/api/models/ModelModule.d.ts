type ModelModulesFilter = {
  nameCont: string
}

interface ModelModuleParams extends CollectionParams {
  filters: ModelModulesFilter
}

type ModelModule = {
  id: string
}
