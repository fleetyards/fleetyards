type TEquipmentFilter = {
  nameCont: string;
  manufacturer: TManufacturer;
  media: {
    storeImage?: FyMediaImage;
  };
};

type TEquipmentParams = TCollectionParams<TEquipmentFilter>;

type TEquipment = {
  id: string;
};
