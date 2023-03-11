type TFleetInviteUrl = {
  token: string;
  url: string;
  expired: boolean;
  expiresAfter: string | null;
  expiresAfterLabel: string | null;
  limit: number | null;
  limitReached: boolean;
};

type TInviteUrlForm = {
  expiresAfterMinutes: number | null;
  limit: number | null;
  fleetSlug: string;
};
interface TFleetInviteUrlParams extends TCollectionParams<undefined> {
  fleetSlug: string;
}
