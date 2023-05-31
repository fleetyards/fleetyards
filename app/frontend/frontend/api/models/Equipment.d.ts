type TEquipmentFilter = {
  nameCont: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TEquipmentParams = TCollectionParams<TEquipmentFilter>;

type TEquipment = {
  id: string;
  manufacturer: TManufacturer;
};
