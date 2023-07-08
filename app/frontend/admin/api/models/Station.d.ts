type AdminStation = {
  id: string;
  name: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type AdminStationsFilter = {
  idEq?: string;
  idIn?: string[];
  nameCont?: string;
};

interface AdminAdminStationParams extends CollectionParams {
  filters: AdminStationsFilter;
}
