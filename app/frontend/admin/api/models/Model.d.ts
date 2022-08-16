type AdminModel = {
  id: string
}

type AdminModelsFilter = {
  idEq: string
  nameCont: string
}

interface AdminAdminModelParams extends CollectionParams {
  filters: AdminModelsFilter
}
