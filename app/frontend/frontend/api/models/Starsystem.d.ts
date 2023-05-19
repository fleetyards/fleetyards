type Starsystem = {
  id: string;
  slug: string;
  name: string;
  locationLabel: string;
};

type StarsystemFilter = {
  nameCont: string;
};

interface StarsystemParams extends CollectionParams {
  filters: StarsystemFilter;
}
