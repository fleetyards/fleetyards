type ComponentsFilter = {
  nameCont: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

interface ComponentParams extends CollectionParams {
  filters: ComponentsFilter;
}

type Component = {
  id: string;
};
