import type { MaybeRefOrGetter } from "vue";
import { useQueries } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import type {
  FleetInventoryTarget,
  InventoryTarget,
} from "@/frontend/types/logistics";
import {
  FeatureFlagName,
  type FilterOption,
  getFleetInventoriesQueryOptions,
  getFleetMembershipQueryOptions,
  useHangarInventories,
  useMyFleets,
} from "@/services/fyApi";

export type DepositTarget = InventoryTarget | FleetInventoryTarget;

type Entry = { option: FilterOption; target: DepositTarget };

/**
 * Every inventory the reader may deposit into, for a form that belongs to none
 * of them: their own and their ships' holds first, then each fleet's, grouped
 * by owner.
 *
 * A fleet is asked for its inventories only where the reader's membership may
 * update them. The API answers the rest -- a fleet without logistics, or
 * without the subscription, refuses, and an inventory hidden from the reader is
 * never listed -- so a fleet that refuses simply offers nothing.
 */
export const useDepositTargets = (enabled: MaybeRefOrGetter<boolean>) => {
  const { t } = useI18n();
  const { isFeatureEnabled } = useFeatures();

  const hangarEnabled = computed(
    () =>
      toValue(enabled) && isFeatureEnabled(FeatureFlagName.HANGAR_INVENTORIES),
  );
  const fleetEnabled = computed(
    () => toValue(enabled) && isFeatureEnabled(FeatureFlagName.FLEET_LOGISTICS),
  );

  const hangar = useHangarInventories(
    { perPage: "240" },
    { query: { enabled: hangarEnabled, retry: false } },
  );

  const fleets = useMyFleets({
    query: { enabled: fleetEnabled, retry: false },
  });

  const fleetList = computed(() => fleets.data.value ?? []);

  const memberships = useQueries({
    queries: computed(() =>
      fleetList.value.map((fleet) =>
        getFleetMembershipQueryOptions(fleet.slug, {
          query: { enabled: fleetEnabled, retry: false },
        }),
      ),
    ),
  });

  const depositFleets = computed(() =>
    fleetList.value.filter(
      (_, at) =>
        memberships.value[at]?.data?.capabilities?.updateInventories ?? false,
    ),
  );

  const fleetInventories = useQueries({
    queries: computed(() =>
      depositFleets.value.map((fleet) =>
        getFleetInventoriesQueryOptions(
          fleet.slug,
          { perPage: "240" },
          { query: { enabled: fleetEnabled, retry: false } },
        ),
      ),
    ),
  });

  // A ship's hold shares its slug with every other ship of its model, so each
  // option is keyed by the inventory's id and filed through the ship.
  const entries = computed<Entry[]>(() => {
    const personal = t("labels.logistics.personalInventory");

    const own = (hangar.data.value?.items ?? []).map((inventory) => ({
      option: {
        value: inventory.id,
        label: inventory.name,
        category: personal,
      },
      target: inventory.vehicle
        ? ({ kind: "vehicle", vehicleId: inventory.vehicle.id } as const)
        : ({ kind: "hangar", slug: inventory.slug } as const),
    }));

    const shared = depositFleets.value.flatMap((fleet, at) =>
      (fleetInventories.value[at]?.data?.items ?? []).map((inventory) => ({
        option: {
          value: inventory.id,
          label: inventory.name,
          category: fleet.name,
        },
        target: {
          kind: "fleet",
          fleetSlug: fleet.slug,
          slug: inventory.slug,
        } as const,
      })),
    );

    return [...own, ...shared];
  });

  const options = computed(() => entries.value.map((entry) => entry.option));

  const targetFor = (value?: string) =>
    entries.value.find((entry) => entry.option.value === value)?.target;

  // Settled once every list asked for has answered, either way: a failed
  // request says nothing about whether there are inventories, so only a
  // complete set of answers with nothing in them is "none".
  const settled = computed(
    () =>
      (!hangarEnabled.value || !hangar.isPending.value) &&
      (!fleetEnabled.value ||
        (!fleets.isPending.value &&
          memberships.value.every((result) => !result.isPending) &&
          fleetInventories.value.every((result) => !result.isPending))),
  );

  // A fleet refusing its inventories is expected, and is not a failure.
  const failed = computed(() => hangar.isError.value || fleets.isError.value);

  const empty = computed(
    () => settled.value && !failed.value && !options.value.length,
  );

  return { options, targetFor, empty };
};
