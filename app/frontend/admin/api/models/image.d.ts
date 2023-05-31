type TAdminImage = {
  id: string;
  caption: string;
  enabled: boolean;
  global: boolean;
};

interface TAdminGalleryParams extends TCollectionParams<TAdminImageFilters> {
  galleryType: string;
  galleryId: string;
}

type TAdminImageFilters = {
  modelIdEq: string;
  stationIdEq: string;
};

type TAdminImageParams = TCollectionParams<TAdminImageFilters>;
