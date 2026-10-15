<script lang="ts">
export default {
  name: "VehicleOverviewConfigurationCard",
};
</script>

<script lang="ts" setup>
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

type Fact = {
  key: string;
  label: string;
  value?: string;
  edit?: () => void;
};

const comlink = useComlink();

const openLocationModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/LocationModal/index.vue"),
    props: { vehicle: props.vehicle },
  });
};

const { openEditModal } = useVehicleModals();

const openGroupsModal = () =>
  openEditModal(props.vehicle, { tab: VehicleEditTabsEnum.GROUPS });

// What the ship carries is edited with the rest of the vehicle; which of it is
// fitted belongs to a loadout.
const editEquipment = (tab: VehicleEditTabsEnum) =>
  openEditModal(props.vehicle, { tab });

const paintThumb = computed(() => props.vehicle.paintPicture?.smallUrl);

const ownedPaints = computed(() =>
  props.vehicle.modelPaintIds.length
    ? t("labels.vehicleOverview.ownedPaintsCount", {
        count: props.vehicle.modelPaintIds.length,
      })
    : t("labels.vehicleOverview.noPaint"),
);

const facts = computed(() =>
  (
    [
      {
        key: "upgrade",
        edit: () => editEquipment(VehicleEditTabsEnum.UPGRADES),
        label: t("labels.model.upgrades"),
        value: props.vehicle.upgrade?.name,
      },
      {
        key: "modulePackage",
        edit: () => editEquipment(VehicleEditTabsEnum.MODULES),
        label: t("labels.model.modulePackages"),
        value: props.vehicle.modulePackage?.name,
      },
      {
        key: "boughtVia",
        edit: () => openEditModal(props.vehicle),
        label: t("labels.vehicle.boughtViaSelect.label"),
        value: props.vehicle.boughtViaLabel,
      },
      {
        key: "bundledParent",
        label: t("labels.vehicle.bundled"),
        value: props.vehicle.bundledParent?.customName
          ? `${props.vehicle.bundledParent.customName} (${props.vehicle.bundledParent.name})`
          : props.vehicle.bundledParent?.name,
      },
      {
        key: "alternativeNames",
        edit: () =>
          openEditModal(props.vehicle, { tab: VehicleEditTabsEnum.NAMES }),
        label: t("headlines.hangar.alternativeNames"),
        value: props.vehicle.alternativeNames.join(", "),
      },
    ] as Fact[]
  ).filter((fact) => !!fact.value),
);
</script>

<template>
  <MetricsCard
    :title="t('labels.vehicleOverview.configuration')"
    variant="slim"
    data-test="vehicle-overview-configuration"
  >
    <dl class="overview-config">
      <div class="overview-config__paint" data-test="vehicle-fact-paint">
        <img
          v-if="paintThumb"
          :src="paintThumb"
          alt=""
          class="overview-config__thumb"
        />
        <div>
          <dt>{{ t("labels.vehicle.ownedPaintsSelect.label") }}</dt>
          <dd>
            <button
              class="overview-config__edit"
              :disabled="vehicle.loaner || !vehicle.model.hasPaints"
              @click="editEquipment(VehicleEditTabsEnum.PAINT)"
            >
              <span>{{ ownedPaints }}</span>
              <i
                v-if="!vehicle.loaner && vehicle.model.hasPaints"
                class="fa-light fa-pen"
                aria-hidden="true"
              />
            </button>
          </dd>
        </div>
      </div>
      <div class="overview-config__fact" data-test="vehicle-fact-location">
        <dt>{{ t("labels.vehicleOverview.location") }}</dt>
        <dd>
          <button
            class="overview-config__edit"
            :disabled="vehicle.loaner"
            data-test="vehicle-location-edit"
            @click="openLocationModal"
          >
            <span>{{
              vehicle.location || t("labels.vehicleOverview.noLocation")
            }}</span>
            <i
              v-if="!vehicle.loaner"
              class="fa-light fa-pen"
              aria-hidden="true"
            />
          </button>
        </dd>
      </div>
      <div
        v-for="fact in facts"
        :key="fact.key"
        class="overview-config__fact"
        :data-test="`vehicle-fact-${fact.key}`"
      >
        <dt>{{ fact.label }}</dt>
        <dd>
          <button
            v-if="fact.edit && !vehicle.loaner"
            class="overview-config__edit"
            @click="fact.edit"
          >
            <span>{{ fact.value }}</span
            ><i class="fa-light fa-pen" aria-hidden="true" />
          </button>
          <span v-else>{{ fact.value }}</span>
        </dd>
      </div>
      <div
        v-if="!vehicle.wanted"
        class="overview-config__fact"
        data-test="vehicle-fact-hangarGroups"
      >
        <dt>{{ t("labels.vehicle.hangarGroups") }}</dt>
        <dd>
          <button
            class="overview-config__edit"
            :disabled="vehicle.loaner"
            data-test="vehicle-groups-edit"
            @click="openGroupsModal"
          >
            <span
              v-if="vehicle.hangarGroups.length"
              class="overview-config__groups"
            >
              <span
                v-for="group in vehicle.hangarGroups"
                :key="group.id"
                class="overview-config__group"
              >
                <span
                  class="overview-config__group-dot"
                  :style="{ backgroundColor: group.color }"
                />
                {{ group.name }}
              </span>
            </span>
            <span v-else>{{ t("labels.vehicleOverview.noGroups") }}</span>
            <i
              v-if="!vehicle.loaner"
              class="fa-light fa-pen"
              aria-hidden="true"
            />
          </button>
        </dd>
      </div>
    </dl>
  </MetricsCard>
</template>

<style lang="scss" scoped>
.overview-config {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin: 0;

  dt {
    color: var(--color-text-dim);
    font-size: 0.8rem;
    font-weight: normal;
  }

  dd {
    margin: 0;
    color: #e6e6e6;
  }

  &__paint {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  &__thumb {
    width: 64px;
    height: 40px;
    border-radius: 4px;
    object-fit: cover;
  }

  &__paint > div {
    flex: 1;
  }

  &__fact:hover .overview-config__edit i,
  &__paint:hover .overview-config__edit i {
    opacity: 1;
  }

  &__edit {
    width: 100%;
    padding: 0;
    border: 0;
    background: transparent;
    color: inherit;
    text-align: left;
    font: inherit;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;

    &:disabled {
      cursor: default;
    }
    i {
      opacity: 0;
      transition: opacity 150ms ease;
    }
    &:hover i,
    &:focus-visible i {
      opacity: 1;
    }
  }

  &__groups {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  &__group {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 2px 10px;
    border-radius: 999px;
    background: var(--color-gray-black);
    font-size: 0.85rem;
  }

  &__group-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
  }

  &__fact {
    padding-top: 10px;
    border-top: 1px solid var(--color-edge-faint);
  }
}
</style>
