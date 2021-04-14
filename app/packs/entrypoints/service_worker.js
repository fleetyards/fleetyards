import { precacheAndRoute } from 'workbox-precaching'
import { registerRoute } from 'workbox-routing'
import { CacheFirst, NetworkFirst } from 'workbox-strategies'

// eslint-disable-next-line no-restricted-globals
precacheAndRoute(self.__WB_MANIFEST)

registerRoute(
  ({ url }) =>
    url.origin === 'https://kit.fontawesome.com' ||
    url.origin === 'https://kit-pro.fontawesome.com' ||
    url.origin === 'https://fonts.googleapis.com' ||
    url.origin === 'https://fonts.gstatic.com',
  new CacheFirst({ cacheName: 'fonts' }),
  'GET',
)

registerRoute(new RegExp('/'), new NetworkFirst({}), 'GET')
