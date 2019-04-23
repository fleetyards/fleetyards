import app from 'frontend/lib/Store/modules/app'
import session from 'frontend/lib/Store/modules/session'
import hangar from 'frontend/lib/Store/modules/hangar'
import models from 'frontend/lib/Store/modules/models'
import stations from 'frontend/lib/Store/modules/stations'
import shops from 'frontend/lib/Store/modules/shops'
import shop from 'frontend/lib/Store/modules/shop'
import tradehubs from 'frontend/lib/Store/modules/tradehubs'
import compare from 'frontend/lib/Store/modules/compare'
import sentry from 'frontend/lib/Store/modules/sentry'

export default () => ({
  app: app(),
  session: session(),
  hangar: hangar(),
  models: models(),
  stations: stations(),
  shops: shops(),
  shop: shop(),
  tradehubs: tradehubs(),
  compare: compare(),
  sentry: sentry(),
})
