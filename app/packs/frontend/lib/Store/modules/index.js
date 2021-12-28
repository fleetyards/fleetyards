import app from 'frontend/lib/Store/modules/app'
import session from 'frontend/lib/Store/modules/session'
import cookies from 'frontend/lib/Store/modules/cookies'
import fleet from 'frontend/lib/Store/modules/fleet'
import publicFleet from 'frontend/lib/Store/modules/publicFleet'
import hangar from 'frontend/lib/Store/modules/hangar'
import publicHangar from 'frontend/lib/Store/modules/publicHangar'
import models from 'frontend/lib/Store/modules/models'
import stations from 'frontend/lib/Store/modules/stations'
import shops from 'frontend/lib/Store/modules/shops'
import shop from 'frontend/lib/Store/modules/shop'
import search from 'frontend/lib/Store/modules/search'
import shoppingCart from 'frontend/lib/Store/modules/shoppingCart'

export default () => ({
  app: app(),
  session: session(),
  cookies: cookies(),
  fleet: fleet(),
  publicFleet: publicFleet(),
  hangar: hangar(),
  publicHangar: publicHangar(),
  models: models(),
  stations: stations(),
  shops: shops(),
  shop: shop(),
  search: search(),
  shoppingCart: shoppingCart(),
})
