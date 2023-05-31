type TImage = {
  id: string;
  name: string;
  url: string;
  width: number;
  height: number;
  smallUrl: string;
  model?: Model;
};

type TImageFilters = {
  galleryType?: "models" | "stations";
  gallerySlug?: string;
};

type TImageParams = TCollectionParams<TImageFilters>;
