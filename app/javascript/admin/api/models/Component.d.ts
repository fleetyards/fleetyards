type AdminComponent = {
  id: string
}

type AdminComponentFilter = {
  nameCont: string
}

interface AdminComponentParams extends CollectionParams {
  filters: AdminComponentFilter
}
