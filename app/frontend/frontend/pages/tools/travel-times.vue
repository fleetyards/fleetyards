<script lang="ts">
export default {
  name: "ToolsTravelTimesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import {
  type BaseTableCol,
  BaseTableColAlignmentEnum,
} from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import TravelTime from "@/frontend/components/TravelTime/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import {
  useComponents as useComponentsQuery,
  getComponentsQueryKey,
  type ComponentQuantumDrive,
  type Component,
} from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { useMobile } from "@/shared/composables/useMobile";
import { quantumDriveTravelTime } from "@/frontend/utils/travelTimes";
import {
  InputTypesEnum,
  InputAlignmentsEnum,
} from "@/shared/components/base/FormInput/types";
import FeatureGuard from "@/frontend/components/FeatureGuard.vue";
import { FeatureFlagName } from "@/services/fyApi";

const { t, toNumber } = useI18n();

const route = useRoute();

const columns = computed<BaseTableCol<Component>[]>(() => {
  return [
    {
      name: "storeImage",
      label: "",
      class: "store-image extra-small",
    },
    {
      name: "name",
      label: t("labels.travelTimes.quantumDrive"),
      class: "name",
      width: "30%",
    },
    {
      name: "fuel_usage",
      label: t("labels.travelTimes.fuelUsage"),
      class: "fuel-usage",
      width: "30%",
      alignment: BaseTableColAlignmentEnum.RIGHT,
    },
    {
      name: "travel_time",
      label: t("labels.travelTimes.travelTime"),
      class: "travel-time",
      width: "30%",
      alignment: BaseTableColAlignmentEnum.RIGHT,
    },
  ];
});

const distance = ref(20);

const { supported: webpSupported } = useWebpCheck();

const mobile = useMobile();

const storeImage = (component: Component) => {
  if (mobile.value && component.media.storeImage?.mediumUrl) {
    return component.media.storeImage?.mediumUrl;
  }

  if (component.media.storeImage?.largeUrl) {
    return component.media.storeImage?.largeUrl;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
};

const isQuantumDrive = (
  typeData?: Component["typeData"],
): typeData is ComponentQuantumDrive => {
  return !!typeData && "quantumFuelConsumption" in typeData;
};

/*
 * Quantum fuel burnt over the jump, in SCU. `quantumFuelConsumption` is
 * milli-SCU per Gm, and a Gm is a million kilometres -- the same unit the
 * distance is collected in -- so the jump costs rate * distance milli-SCU.
 *
 * The drive also carries `quantumFuelRequirement`, which is what this column
 * used to read. Nothing else in the app touches that field and no unit is
 * declared for it anywhere; the consumption figure is the one the hardpoint
 * panel derives its jump range from, checked against erkul.games and
 * spviewer.eu.
 */
const fuelUsage = (component: Component): number | undefined => {
  if (!isQuantumDrive(component.typeData)) {
    return undefined;
  }

  const rate = component.typeData.quantumFuelConsumption;

  if (!rate) {
    return undefined;
  }

  return Math.round(((rate * distance.value) / 1000) * 100) / 100;
};

const sortedQuantumDrives = computed(() => {
  return [...(quantumDrives.value?.items || [])].sort((a, b) => {
    const aTravelTime = quantumDriveTravelTime(a, distance.value);
    const bTravelTime = quantumDriveTravelTime(b, distance.value);

    if (!aTravelTime) {
      return 1;
    }

    if (!bTravelTime) {
      return -1;
    }

    if (aTravelTime < bTravelTime) {
      return -1;
    }

    if (aTravelTime > bTravelTime) {
      return 1;
    }

    return 0;
  });
});

const componentsQueryParams = computed(() => ({
  page: page.value,
  perPage: "240",
  q: {
    categoryIn: ["quantumdrive"],
  },
}));

const componentsQueryKey = computed(() => {
  return getComponentsQueryKey(componentsQueryParams.value);
});

const { page, perPage, updatePerPage } = usePagination(componentsQueryKey);

const { data: quantumDrives, ...asyncStatus } = useComponentsQuery(
  componentsQueryParams,
);
</script>

<template>
  <FeatureGuard :feature="FeatureFlagName.TOOLS_TRAVEL_TIMES">
    <Heading>{{ t(`headlines.${route.meta.title}`) }}</Heading>

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model.number="distance"
          :min="1"
          name="distance"
          :type="InputTypesEnum.NUMBER"
          inline
          :alignment="InputAlignmentsEnum.RIGHT"
          suffix="Mkm"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12">
        <p>
          {{ t("labels.travelTimes.poweredBy") }}
          <a
            href="https://gitlab.com/Erecco/a-study-on-quantum-travel-time/-/blob/master/A_study_on_Quantum_Travel_time_07042021.pdf?ref_type=heads"
            >Erec</a
          >
        </p>
      </div>
    </div>

    <FilteredList
      key="quantumDrives"
      :paginated="true"
      :records="sortedQuantumDrives"
      :name="route.name?.toString() || ''"
      :async-status="asyncStatus"
      placeholders
    >
      <template #default="{ records }">
        <BaseTable
          :records="records"
          :filter-visible="false"
          primary-key="slug"
          :columns="columns"
        >
          <template #col-storeImage="{ record }">
            <div
              :key="storeImage(record)"
              :style="{ backgroundImage: `url(${storeImage(record)})` }"
              class="image"
              alt="storeImage"
            />
          </template>
          <template #col-name="{ record }">
            {{ record.name }}
          </template>
          <template #col-fuel_usage="{ record }">
            <template v-if="fuelUsage(record)">
              {{ toNumber(fuelUsage(record)!, "cargo") }}
            </template>
            <template v-else> - </template>
          </template>
          <template #col-travel_time="{ record }">
            <TravelTime :quantum-drive="record" :distance="distance" />
          </template>
        </BaseTable>
      </template>

      <template #pagination-top>
        <Paginator
          :query-result-ref="quantumDrives"
          :per-page="perPage"
          :update-per-page="updatePerPage"
        />
      </template>

      <template #pagination-bottom>
        <Paginator
          :query-result-ref="quantumDrives"
          :per-page="perPage"
          :update-per-page="updatePerPage"
        />
      </template>
    </FilteredList>
  </FeatureGuard>
</template>
