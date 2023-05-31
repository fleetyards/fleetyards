type TModelHardpoint = {
  id: string;
  type: string;
  categoryLabel: string;
  category: string;
  component: TComponent;
  itemSlots: number;
  size: number;
  details: string;
  sizeLabel: string;
  group: string;
  loadouts: TModelHardpointLoadout[];
};

type TModelHardpointLoadout = {
  component: TComponent;
};
