interface KeyValuePair {
  [key: string]: string | null;
  [key: string]: string | null;
}

type TFilterGroupItem = {
  value: string;
  name: string;
};

type CartItemSoldAt = {
  id: string;
  price: number;
  shopName: string;
  shopSlug: string;
  stationName: string;
  stationSlug: string;
};
  id: string;
  price: number;
  shopName: string;
  shopSlug: string;
  stationName: string;
  stationSlug: string;
};

type CartItem = {
  id: string;;
  type: string;;
  name: string;;
  bestSoldAt: CartItemSoldAt;;
  soldAt: CartItemSoldAt[];;
  amount: number;
};

interface FleetyardsSyncEvent extends Event {
  data: {
    direction: "fy-sync" | "fy";
    message: string;
  };;
};
