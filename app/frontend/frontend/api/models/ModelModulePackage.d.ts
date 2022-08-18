type ModelModulePackagesFilter = {
  nameCont: string
}

interface ModelModulePackageParams extends CollectionParams {
  filters: ModelModulesFilter
}

type ModelModulePackage = {
  id: string
}
