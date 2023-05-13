type Image = {
  id: string;
  name: string;
  smallUrl: string;
  model?: Model;
};

interface GalleryParams extends CollectionParams {
  galleryType: string;
  slug: string;
}
