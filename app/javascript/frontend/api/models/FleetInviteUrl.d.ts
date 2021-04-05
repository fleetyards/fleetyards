type FleetInviteUrl = {
  token: string
  url: string
  expired: boolean
  expiresAfter: string | null
  expiresAfterLabel: string | null
  limit: number | null
  limitReached: boolean
}

type InviteUrlForm = {
  expiresAfterMinutes: number | null
  limit: number | null
  fleetSlug: string
}
interface FleetInviteUrlParams extends CollectionParams {
  fleetSlug: string
}
