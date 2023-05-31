type TImage = {
  id: string;
  name: string;
  url: string;
  width: number;
  height: number;
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
