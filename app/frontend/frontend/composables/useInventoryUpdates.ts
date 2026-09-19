import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  useSubscription,
  type ConnectEvent,
} from "@/shared/composables/useSubscription";
import { useDebouncedRefresh } from "@/shared/composables/useDebouncedRefresh";
import { HangarInventoryChannel } from "@/services/fyCable/channels/HangarInventoryChannel";
import { FleetInventoryChannel } from "@/services/fyCable/channels/FleetInventoryChannel";
import { FeatureFlagName } from "@/services/fyApi";

/**
 * An inventory whose contents changed.
 *
 * `fleetSlug` is set where the store is a fleet's rather than the reader's
 * own, which is also what tells the two apart: one reader holds one
 * subscription for every fleet they are in.
 */
export type InventoryChange = {
  inventoryId: string;
  inventorySlug: string;
  fleetSlug?: string;
};

type Options = {
  /**
   * Which changes this caller cares about. Applied before the debounce, not
   * after: a burst spanning two fleets would otherwise collapse to whichever
   * ping happened to land last, and a page watching the other one would never
   * hear about its own change.
   */
  filter?: (change: InventoryChange) => boolean;
};

/**
 * Refetch when stock moves.
 *
 * Both channels, because a reader's materials can sit in their own hangar and
 * in their fleets' stores at once, and a page showing both has one question:
 * has anything I am displaying changed.
 *
 * The broadcast is a ping rather than the stock itself -- what a page shows is
 * a rolled-up position, not the entry that moved -- so this refetches rather
 * than patching anything in place.
 */
export const useInventoryUpdates = (
  refresh: () => unknown,
  { filter }: Options = {},
) => {
  const { isAuthenticated } = storeToRefs(useSessionStore());
  const { isFeatureEnabled } = useFeatures();

  const refreshDebounced = useDebouncedRefresh(refresh);

  const hangarEnabled = computed(
    () =>
      isAuthenticated.value &&
      isFeatureEnabled(FeatureFlagName.HANGAR_INVENTORIES),
  );

  const fleetEnabled = computed(
    () =>
      isAuthenticated.value &&
      isFeatureEnabled(FeatureFlagName.FLEET_LOGISTICS),
  );

  const received = (change: InventoryChange) => {
    if (filter && !filter(change)) {
      return;
    }

    refreshDebounced();
  };

  // Nothing broadcast while the socket was down is replayed, so a reconnect
  // resyncs rather than waiting for whatever changes next. The first connect
  // is left alone: the page has just loaded its own data.
  const connected = ({ reconnect }: ConnectEvent) => {
    if (reconnect) {
      refreshDebounced();
    }
  };

  useSubscription({
    channel: HangarInventoryChannel,
    enabled: hangarEnabled,
    received,
    connected,
  });

  useSubscription({
    channel: FleetInventoryChannel,
    enabled: fleetEnabled,
    received,
    connected,
  });
};
