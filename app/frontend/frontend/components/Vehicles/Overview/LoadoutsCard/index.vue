<script lang="ts">
export default {
  name: "VehicleOverviewLoadoutsCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Vehicle,
  type VehicleLoadout,
  getVehicleLoadoutsQueryKey,
  useActivateVehicleLoadout,
  useVehicleLoadouts,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data: loadouts, isLoading } = useVehicleLoadouts(
  () => props.vehicle.id,
);

const all = computed<VehicleLoadout[]>(() => loadouts.value || []);

const name = (loadout: VehicleLoadout) =>
  loadout.name || loadout.urlSource || loadout.url || "";

// A fleetyards loadout is kept here rather than on another site, so it opens
// here and names its kind where a link names its site.
const source = (loadout: VehicleLoadout) =>
  loadout.urlSource ||
  (loadout.url ? undefined : t("labels.loadout.fleetyards"));

const icon = (loadout: VehicleLoadout) =>
  loadout.url ? "fa-duotone fa-link" : "fa-duotone fa-crosshairs";

const badges = (loadout: VehicleLoadout) =>
  loadout.active
    ? [
        {
          key: "active",
          label: t("labels.loadout.active"),
          variant: PillVariantsEnum.SUCCESS,
        },
      ]
    : [];

const queryClient = useQueryClient();

const { invalidateVehiclePage } = useVehicleMutations();

// The vehicle carries its active loadout, which the header's stats and badge
// are read from.
const activateMutation = useActivateVehicleLoadout({
  mutation: {
    onSettled: () =>
      Promise.all([
        queryClient.invalidateQueries({
          queryKey: getVehicleLoadoutsQueryKey(props.vehicle.id),
        }),
        invalidateVehiclePage(props.vehicle),
      ]),
  },
});

const activate = (loadout: VehicleLoadout) => {
  if (loadout.active || activateMutation.isPending.value) return;

  activateMutation.mutate({ vehicleId: props.vehicle.id, id: loadout.id });
};

const { openLoadoutView } = useVehicleModals();

const view = (loadout: VehicleLoadout) => {
  openLoadoutView(props.vehicle, { editable: true, loadout });
};

const toVehicle = useVehicleRoute();

const loadoutsRoute = computed(() =>
  toVehicle("hangar-vehicle-loadouts", props.vehicle),
);
</script>

<template>
  <MetricsCard
    :title="t('nav.hangar.vehicleLoadouts')"
    :loading="isLoading"
    variant="slim"
    data-test="vehicle-overview-loadouts"
  >
    <p v-if="!isLoading && !all.length" class="overview-card-muted">
      {{ t("texts.vehicleOverview.noLoadouts") }}
    </p>

    <ul
      v-if="all.length"
      class="overview-loadouts"
      :aria-busy="activateMutation.isPending.value"
    >
      <li
        v-for="loadout in all"
        :key="loadout.id"
        class="overview-loadouts__item"
      >
        <!-- A click on a row switches that loadout on, which nothing else on
             the row says. -->
        <AddonOption
          v-tooltip="
            loadout.active
              ? t('labels.loadout.activeHint')
              : t('labels.loadout.activateHint')
          "
          :name="name(loadout)"
          :icon="icon(loadout)"
          :contents="source(loadout)"
          :badges="badges(loadout)"
          :selected="loadout.active"
          :test-id="`vehicle-overview-loadout-${loadout.id}`"
          class="overview-loadouts__option"
          @toggle="activate(loadout)"
        />
        <Btn
          v-if="loadout.url"
          v-tooltip="t('actions.vehicleLoadout.viewLoadout')"
          :aria-label="t('actions.vehicleLoadout.viewLoadout')"
          :href="loadout.url"
          variant="ghost"
          :data-test="`vehicle-overview-loadout-${loadout.id}-view`"
        >
          <i class="fa-duotone fa-arrow-up-right-from-square" />
        </Btn>
        <Btn
          v-else
          v-tooltip="t('actions.vehicleLoadout.viewLoadout')"
          :aria-label="t('actions.vehicleLoadout.viewLoadout')"
          variant="ghost"
          :data-test="`vehicle-overview-loadout-${loadout.id}-view`"
          @click="view(loadout)"
        >
          <i class="fa-duotone fa-up-right-and-down-left-from-center" />
        </Btn>
      </li>
    </ul>

    <template #footer>
      <router-link :to="loadoutsRoute" class="overview-card-footer-link">
        {{ t("actions.hangar.manageLoadouts") }}
      </router-link>
    </template>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "../card.scss";

.overview-loadouts {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0 0 8px;
  padding: 0;
  list-style: none;

  &[aria-busy="true"] {
    cursor: progress;
  }

  &__item {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  &__option {
    flex: 1;
    min-width: 0;
    padding: 8px 12px 8px 8px;
    gap: 12px;

    // The editor's thumbnail is sized for a store image; a card row only
    // carries the loadout's kind.
    :deep(.addon-option__image) {
      width: 40px;
      height: 40px;

      i,
      svg {
        font-size: 18px;
      }
    }

    :deep(.addon-option__name) {
      font-size: 14px;
      font-weight: 600;
    }

    :deep(.addon-option__contents) {
      font-size: 12px;
    }
  }
}
</style>
