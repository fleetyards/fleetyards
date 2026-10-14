<script lang="ts">
export default {
  name: "VehicleOverviewConfigurationCard",
};
</script>

<script lang="ts" setup>
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
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

const paintThumb = computed(
  () => props.vehicle.paint?.media.storeImage?.smallUrl,
);

const facts = computed(() =>
  (
    [
      {
        key: "upgrade",
        label: t("labels.model.upgrades"),
        value: props.vehicle.upgrade?.name,
      },
      {
        key: "modulePackage",
        label: t("labels.model.modulePackages"),
        value: props.vehicle.modulePackage?.name,
      },
      {
        key: "boughtVia",
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
          <dt>{{ t("labels.vehicle.modelPaintSelect.label") }}</dt>
          <dd>
            {{ vehicle.paint?.name || t("labels.vehicleOverview.noPaint") }}
          </dd>
        </div>
      </div>
      <div class="overview-config__fact" data-test="vehicle-fact-location">
        <dt>{{ t("labels.vehicleOverview.location") }}</dt>
        <dd class="overview-config__editable">
          <span>
            {{ vehicle.location || t("labels.vehicleOverview.noLocation") }}
          </span>
          <Btn
            v-if="!vehicle.loaner"
            :size="BtnSizesEnum.XS"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('actions.vehicleOverview.editLocation')"
            data-test="vehicle-location-edit"
            @click="openLocationModal"
          >
            <i class="fa-light fa-pen" />
          </Btn>
        </dd>
      </div>
      <div
        v-for="fact in facts"
        :key="fact.key"
        class="overview-config__fact"
        :data-test="`vehicle-fact-${fact.key}`"
      >
        <dt>{{ fact.label }}</dt>
        <dd>{{ fact.value }}</dd>
      </div>
      <div
        v-if="!vehicle.wanted"
        class="overview-config__fact"
        data-test="vehicle-fact-hangarGroups"
      >
        <dt>{{ t("labels.vehicle.hangarGroups") }}</dt>
        <dd class="overview-config__editable">
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
          <Btn
            v-if="!vehicle.loaner"
            :size="BtnSizesEnum.XS"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('actions.hangar.editGroups')"
            data-test="vehicle-groups-edit"
            @click="openGroupsModal"
          >
            <i class="fa-light fa-pen" />
          </Btn>
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

  &__editable {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
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
