import app from "@/frontend/lib/Store/modules/app";
import publicFleet from "@/frontend/lib/Store/modules/publicFleet";
import publicHangar from "@/frontend/lib/Store/modules/publicHangar";
import wishlist from "@/frontend/lib/Store/modules/wishlist";
import publicWishlist from "@/frontend/lib/Store/modules/publicWishlist";
import models from "@/frontend/lib/Store/modules/models";
import stations from "@/frontend/lib/Store/modules/stations";
import shops from "@/frontend/lib/Store/modules/shops";
import shop from "@/frontend/lib/Store/modules/shop";

export default () => ({
  app: app(),
  publicFleet: publicFleet(),
  publicHangar: publicHangar(),
  wishlist: wishlist(),
  publicWishlist: publicWishlist(),
  models: models(),
  stations: stations(),
  shops: shops(),
  shop: shop(),
});
