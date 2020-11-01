type AdminEquipment = {
  id: string
}

type AdminEquipmentFilter = {
  nameCont: string
}

interface AdminEquipmentParams extends CollectionParams {
  filters: AdminEquipmentFilter
}
