type Starsystem = {
  id: string
  slug: string
  name: string
}

type StarsystemFilter = {
  nameCont: string
}

interface StarsystemParams extends CollectionParams {
  filters: StarsystemFilter
}
