type TManufacturer = {
  id: string;
  name: string;
  slug: string;
  code: string;
  logo?: string;
};

type TManufacturerFilters = {
  nameCont: string;
  nameIn: string[];
};

type TManufacturerParams = TCollectionParams<TManufacturerFilters>;
