type EquipmentFilter = {
  nameCont: string
}

interface EquipmentParams extends CollectionParams {
  filters: EquipmentFilter
}

type Equipment = {
  id: string
}
