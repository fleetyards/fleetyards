type Commodity = {
  id: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type CommoditiesFilter = {
  nameCont: string;
};

interface CommodityParams extends CollectionParams {
  filters: CommoditiesFilter;
}
