export const isFleetRoute = function isFleetRoute(routeName: string) {
  return [
    'fleet',
    'fleet-ships',
    'fleet-members',
    'fleet-stats',
    'fleet-fleetchart',
    'fleet-settings',
    'fleet-settings-fleet',
    'fleet-settings-membership',
  ].includes(routeName)
}

export default isFleetRoute
