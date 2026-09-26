import { FeatureFlagName, type Fleet } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

// `subscribed` is optional although the schema types it required: the public
// fleet endpoint is documented as returning a whole Fleet but its view renders
// the base partial only, so a fleet read while signed out carries neither it
// nor `features`. Absent has to read as unsubscribed.
type SubscribableFleet = Pick<Fleet, "features"> &
  Partial<Pick<Fleet, "subscribed">>;

type FleetFeatureCheck = ReturnType<
  typeof useFeatures
>["isFleetFeatureEnabled"];

// While `fleet_subscriptions` is off for a fleet, enforcement does not run and
// entitlement is never asked about -- this is false and every surface behaves
// exactly as it did before any of this shipped.
export const fleetSubscriptionRequired = (
  fleet: SubscribableFleet | undefined,
  isFleetFeatureEnabled: FleetFeatureCheck,
) => {
  // No fleet, nothing to have subscribed -- the same guard the controller
  // concern opens with. It has to come first: `isFleetFeatureEnabled` ORs in
  // the viewer's own flags, so a viewer the rollout is enabled for would
  // otherwise pass the check below with no fleet at all, and the absent
  // `subscribed` would then read as unsubscribed.
  if (!fleet) {
    return false;
  }

  if (!isFleetFeatureEnabled(fleet, FeatureFlagName.FLEET_SUBSCRIPTIONS)) {
    return false;
  }

  return !(fleet.subscribed ?? false);
};

/**
 * The second of the two questions `FleetSubscriptionConcern` asks, for the
 * surfaces that have to answer it before the API is even called. The first --
 * is the capability rolled out here -- stays with the caller, because a
 * capability that is off is unavailable to subscribed and unsubscribed fleets
 * alike and must not be answered with an upsell.
 */
export const useFleetSubscription = (
  fleet: MaybeRefOrGetter<SubscribableFleet | undefined>,
) => {
  const { isFleetFeatureEnabled } = useFeatures();

  const subscriptionRequired = computed(() =>
    fleetSubscriptionRequired(toValue(fleet), isFleetFeatureEnabled),
  );

  return { subscriptionRequired };
};
