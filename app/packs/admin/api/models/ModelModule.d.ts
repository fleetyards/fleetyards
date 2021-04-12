type AdminModelModule = {
  id: string
}

type AdminModelModuleFilter = {
  nameCont: string
}

interface AdminModelModuleParams extends CollectionParams {
  filters: AdminModelModuleFilter
}
