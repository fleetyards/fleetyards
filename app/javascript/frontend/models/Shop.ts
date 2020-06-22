type Shop = {
  id: string
}

type ShopsFilter = {
  nameCont: string
}

interface ShopParams extends CollectionParams {
  filters: ShopsFilter
}
