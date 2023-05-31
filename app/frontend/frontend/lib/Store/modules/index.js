import app from "@/frontend/lib/Store/modules/app";
import cookies from "@/frontend/lib/Store/modules/cookies";
import fleet from "@/frontend/lib/Store/modules/fleet";
import hangar from "@/frontend/lib/Store/modules/hangar";
import models from "@/frontend/lib/Store/modules/models";
import publicFleet from "@/frontend/lib/Store/modules/publicFleet";
import publicHangar from "@/frontend/lib/Store/modules/publicHangar";
import publicWishlist from "@/frontend/lib/Store/modules/publicWishlist";
import search from "@/frontend/lib/Store/modules/search";
import session from "@/frontend/lib/Store/modules/session";
import shop from "@/frontend/lib/Store/modules/shop";
import shoppingCart from "@/frontend/lib/Store/modules/shoppingCart";
import shops from "@/frontend/lib/Store/modules/shops";
import stations from "@/frontend/lib/Store/modules/stations";
import wishlist from "@/frontend/lib/Store/modules/wishlist";

export default () => ({
  app: app(),
  session: session(),
  cookies: cookies(),
  fleet: fleet(),
  publicFleet: publicFleet(),
  hangar: hangar(),
  publicHangar: publicHangar(),
  wishlist: wishlist(),
  publicWishlist: publicWishlist(),
  models: models(),
  stations: stations(),
  shops: shops(),
  shop: shop(),
  search: search(),
  shoppingCart: shoppingCart(),
});
