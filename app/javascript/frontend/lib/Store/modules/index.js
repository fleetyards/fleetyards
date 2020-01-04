import app from 'frontend/lib/Store/modules/app'
import session from 'frontend/lib/Store/modules/session'
import fleet from 'frontend/lib/Store/modules/fleet'
import hangar from 'frontend/lib/Store/modules/hangar'
import models from 'frontend/lib/Store/modules/models'
import stations from 'frontend/lib/Store/modules/stations'
import shops from 'frontend/lib/Store/modules/shops'
import shop from 'frontend/lib/Store/modules/shop'
import compare from 'frontend/lib/Store/modules/compare'
import sentry from 'frontend/lib/Store/modules/sentry'
import search from 'frontend/lib/Store/modules/search'

export default () => ({
  app: app(),
  session: session(),
  fleet: fleet(),
  hangar: hangar(),
  models: models(),
  stations: stations(),
  shops: shops(),
  shop: shop(),
  compare: compare(),
  sentry: sentry(),
  search: search(),
})
