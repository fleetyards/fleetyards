<script lang="ts">
export default {
  name: "ToolsTravelTimes",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import TravelTime from "@/frontend/components/TravelTime/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { type Component } from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { useMobile } from "@/shared/composables/useMobile";
import { calculateTravelTime } from "@/frontend/utils/travelTimes";
import {
  InputTypesEnum,
  InputAlignmentsEnum,
} from "@/shared/components/base/FormInput/types";
import {
  useComponents as useComponentsQuery,
  getComponentsQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const route = useRoute();

const columns = computed<BaseTableColumn[]>(() => {
  return [
    {
      name: "store_image",
      label: "",
      class: "store-image extra-small",
      type: "store-image",
    },
    { name: "name", label: "", class: "name", width: "30%" },
    { name: "fuel_usage", label: "", class: "fuel-usage", width: "30%" },
    { name: "travel_time", label: "", class: "travel-time", width: "30%" },
  ];
});

const distance = ref(20);

const { supported: webpSupported } = useWebpCheck();

const mobile = useMobile();

const storeImage = (component: Component) => {
  if (mobile.value && component.media.storeImage?.medium) {
    return component.media.storeImage?.medium;
  }

  if (component.media.storeImage?.large) {
    return component.media.storeImage?.large;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
};

const travelTime = (quantumDrive: Component) => {
  if (!quantumDrive.typeData?.standardJump) {
    return undefined;
  }

  const a1 =
    (quantumDrive.typeData?.standardJump.stage1AccelerationRate || 0) / 1000;
  const a2 =
    (quantumDrive.typeData?.standardJump.stage2AccelerationRate || 0) / 1000;
  const speed = (quantumDrive.typeData?.standardJump.speed || 0) / 1000;

  return calculateTravelTime(a1, a2, speed, distance.value);
};

const sortedQuantumDrives = computed(() => {
  return [...(quantumDrives.value?.items || [])].sort((a, b) => {
    const aTravelTime = travelTime(a);
    const bTravelTime = travelTime(b);

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
    itemTypeIn: ["quantum_drives"],
  },
}));

const componentsQueryKey = computed(() => {
  return getComponentsQueryKey(componentsQueryParams.value);
});

const { page, perPage, updatePerPage } = usePagination(componentsQueryKey);

const {
  data: quantumDrives,
  refetch,
  ...asyncStatus
} = useComponentsQuery(componentsQueryParams);
</script>

<template>
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="row">
        <div class="col-12">
          <h1 class="sr-only">
            {{ t("headlines.tools.travelTimes") }}
          </h1>
        </div>
      </div>
    </div>
  </div>

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
        powered by
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
  >
    <template #default="{ records }">
      <BaseTable
        :records="records"
        :filter-visible="false"
        primary-key="slug"
        :columns="columns"
      >
        <template #col-store_image="{ record }">
          <div
            :key="storeImage(record)"
            v-lazy:background-image="storeImage(record)"
            class="image lazy"
            alt="storeImage"
          />
        </template>
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-fuel_usage="{ record }">
          <template v-if="record.typeData?.fuelRate">
            {{ Math.round(record.typeData?.fuelRate * distance * 100) / 100.0 }}
          </template>
          <template v-else> - </template>
        </template>
        <template #col-travel_time="{ record }">
          <TravelTime :quantum-drive="record" :distance="distance * 1000000" />
        </template>
      </BaseTable>
    </template>

    <template #pagination-bottom>
      <Paginator
        v-if="quantumDrives"
        :query-result-ref="quantumDrives"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
