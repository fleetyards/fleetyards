type FleetInviteUrl = {
  token: StringConstructor
}

type InviteUrlForm = {
  expiresAfterMinutes: number | null
  limit: number | null
  fleetSlug: string
}
interface FleetInviteUrlParams extends CollectionParams {
  fleetSlug: string
}
