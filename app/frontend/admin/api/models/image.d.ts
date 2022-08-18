type AdminImage = {
  id: string
}

interface AdminGalleryParams extends CollectionParams {
  galleryType: string
  galleryId: string
}

type AdminImageFilters = {
  modelIdEq: string
  stationIdEq: string
}

interface AdminImageParams extends CollectionParams {
  filters: AdminImageFilters
}
