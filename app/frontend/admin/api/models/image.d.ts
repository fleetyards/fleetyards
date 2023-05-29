type TAdminImage = {
  id: string;
};

interface TAdminGalleryParams extends TCollectionParams {
  galleryType: string;
  galleryId: string;
}

type TAdminImageFilters = {
  modelIdEq: string;
  stationIdEq: string;
};

type TAdminImageParams = TCollectionParams<TAdminImageFilters>;
