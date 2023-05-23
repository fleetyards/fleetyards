type EquipmentFilter = {
  nameCont: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

interface EquipmentParams extends CollectionParams {
  filters: EquipmentFilter;
}

type Equipment = {
  id: string;
};
