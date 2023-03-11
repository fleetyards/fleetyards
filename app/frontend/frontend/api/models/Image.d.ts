type TImage = {
  id: string;
  name: string;
  smallUrl: string;
  model?: Model;
};

type TGalleryFilter = {
  galleryIdEq?: string;
  galleryTypeEq?: string;
};

interface TGalleryParams extends TCollectionParams<TGalleryFilter> {
  galleryType: string;
  slug: string;
}
