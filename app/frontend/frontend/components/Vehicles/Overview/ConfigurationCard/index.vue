<script lang="ts">
export default {
  name: "VehicleOverviewConfigurationCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import HangarGroups from "@/frontend/components/Vehicles/HangarGroups/index.vue";
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
        v-if="vehicle.hangarGroups.length"
        class="overview-config__fact"
        data-test="vehicle-fact-hangarGroups"
      >
        <dt>{{ t("labels.vehicle.hangarGroups") }}</dt>
        <dd><HangarGroups :groups="vehicle.hangarGroups" /></dd>
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

  &__fact {
    padding-top: 10px;
    border-top: 1px solid var(--color-edge-faint);
  }
}
</style>
