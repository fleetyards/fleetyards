<script lang="ts">
export default {
  name: "FleetVehiclesTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import type {
  VehiclePublic,
  Model,
  FleetModelCountsStats,
} from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import {
  useFleetStore,
  FleetTableViewColsEnum,
  FleetTableViewImageColsEnum,
} from "@/frontend/stores/fleet";

type FleetVehicle = VehiclePublic | Model;

type Props = {
  fleetSlug: string;
  vehicles: FleetVehicle[];
  loading?: boolean;
  emptyVisible?: boolean;
  modelCounts?: FleetModelCountsStats;
};

const props = defineProps<Props>();

const countLabel = (record: FleetVehicle) => {
  if (!fleetStore.grouped || !record.slug) {
    return "";
  }

  const modelCount = props.modelCounts?.modelCounts?.[record.slug];

  if (!modelCount) {
    return "";
  }

  return `${modelCount}x `;
};

const comlink = useComlink();

const { t, toNumber, toUEC, toDollar } = useI18n();

const mobile = useMobile();

const fleetStore = useFleetStore();

const extraColumns = computed(() => {
  return Object.values(FleetTableViewColsEnum)
    .map((col) => ({
      name: col,
      label: t(`labels.fleetTable.columns.${col}`),
      sortable: true,
    }))
    .filter((col) => fleetStore.tableViewCols.includes(col.name));
});

const extraImageColumns = computed<BaseTableCol<FleetVehicle>[]>(() => {
  return Object.values(FleetTableViewImageColsEnum)
    .map((col) => ({
      name: col,
      label: "",
      width: col.endsWith("Wide") ? "270px" : "120px",
      centered: true,
    }))
    .filter((col) => fleetStore.tableViewImageCols.includes(col.name));
});

const manufacturerColumnVisible = computed(() => {
  return extraColumns.value.some(
    (column) => column.name === "modelManufacturerName",
  );
});

const tableColumns = computed<BaseTableCol<FleetVehicle>[]>(() => {
  return [
    ...extraImageColumns.value,
    {
      name: "name",
      label: t("labels.vehicle.name"),
      width: "auto",
      sortable: true,
    },
    ...extraColumns.value,
  ];
});

const getModel = (record: FleetVehicle): Model => {
  if ((record as VehiclePublic).model) {
    return (record as VehiclePublic).model;
  }
  return record as Model;
};

const storeImage = (record: FleetVehicle) => {
  const vehicle = record as VehiclePublic;

  if (vehicle.paint?.media.storeImage) {
    return vehicle.paint.media.storeImage;
  }

  if (vehicle.upgrade?.media.storeImage) {
    return vehicle.upgrade.media.storeImage;
  }

  return getModel(record).media.storeImage;
};

const angledImage = (record: FleetVehicle) => {
  const model = getModel(record);

  if (model.media.angledViewColored) {
    return model.media.angledViewColored;
  }

  return model.media.angledView;
};

const openOwnersModal = (modelSlug: string) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/OwnersModal/index.vue"),
    props: {
      fleetSlug: props.fleetSlug,
      modelSlug,
    },
  });
};
</script>

<template>
  <div>
    <BaseTable
      :records="vehicles"
      primary-key="id"
      :columns="tableColumns"
      :loading="loading"
      :empty-visible="emptyVisible"
    >
      <template #col-storeImage="{ record }">
        <ViewImage
          :image="storeImage(record)"
          size="small"
          alt="image"
          :variant="LazyImageVariantsEnum.WIDE_SMALL"
          shadow
        />
      </template>
      <template #col-storeImageWide="{ record }">
        <ViewImage
          :image="storeImage(record)"
          size="small"
          alt="image"
          :variant="LazyImageVariantsEnum.WIDE"
          shadow
        />
      </template>
      <template #col-angledView="{ record }">
        <ViewImage
          :image="angledImage(record)"
          size="small"
          alt="image"
          :variant="LazyImageVariantsEnum.WIDE_SMALL"
          transparent
          without-fallback
        />
      </template>
      <template #col-angledViewWide="{ record }">
        <ViewImage
          :image="angledImage(record)"
          size="small"
          alt="image"
          :variant="LazyImageVariantsEnum.WIDE"
          transparent
          without-fallback
        />
      </template>
      <template #col-name="{ record }">
        <div class="name">
          <router-link
            :to="{
              name: 'ship',
              params: {
                slug: getModel(record).slug,
              },
            }"
          >
            <span v-if="record.name"
              >{{ countLabel(record) }}{{ record.name }}</span
            >
            <span v-else
              >{{ countLabel(record) }}{{ getModel(record).name }}</span
            >
          </router-link>
          <br />
          <small>
            <!-- eslint-disable vue/no-v-html -->
            <span
              v-if="getModel(record).manufacturer && !manufacturerColumnVisible"
              v-html="getModel(record).manufacturer?.name"
            />
            <template v-if="record.name">
              {{ getModel(record).name }}
            </template>
          </small>
        </div>
      </template>
      <template #col-modelManufacturerName="{ record }">
        {{ getModel(record).manufacturer?.name }}
      </template>
      <template #col-owner="{ record }">
        <Btn
          v-if="fleetStore.grouped"
          variant="link"
          :text-inline="true"
          @click="openOwnersModal(getModel(record).slug)"
        >
          {{ t("labels.vehicle.owner") }} <i class="fa fa-bars-staggered" />
        </Btn>
        <template v-else>
          {{ (record as VehiclePublic).username }}
        </template>
      </template>
      <template #col-modelLength="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).metrics.length || "", "distance")
        }}</span>
      </template>
      <template #col-modelBeam="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).metrics.beam || "", "distance")
        }}</span>
      </template>
      <template #col-modelHeight="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).metrics.height || "", "distance")
        }}</span>
      </template>
      <template #col-modelMass="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).metrics.mass || "", "weight")
        }}</span>
      </template>
      <template #col-modelCargo="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).metrics.cargo || "", "cargo")
        }}</span>
      </template>
      <template #col-modelMinCrew="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).crew.min || "", "people")
        }}</span>
      </template>
      <template #col-modelMaxCrew="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).crew.max || "", "people")
        }}</span>
      </template>
      <template #col-modelGroundMaxSpeed="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).speeds.groundMaxSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-modelScmSpeed="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).speeds.scmSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-modelMaxSpeed="{ record }">
        <span class="no-break">{{
          toNumber(getModel(record).speeds.maxSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-modelProductionStatus="{ record }">
        {{
          t(
            `labels.model.productionStatus.${getModel(record).productionStatus}`,
          )
        }}
      </template>
      <template #col-modelPrice="{ record }">
        <!-- eslint-disable vue/no-v-html -->
        <div
          v-tooltip="{ content: toUEC(getModel(record).price), html: true }"
          class="no-break"
          v-html="toUEC(getModel(record).price)"
        />
        <!-- eslint-enable vue/no-v-html -->
      </template>
      <template #col-modelPledgePrice="{ record }">
        <span class="no-break">{{
          toDollar(getModel(record).pledgePrice)
        }}</span>
      </template>
      <template #actions="{ record }">
        <Btn
          v-if="!mobile"
          :to="{
            name: 'ship',
            params: {
              slug: getModel(record).slug,
            },
          }"
          :size="BtnSizesEnum.SMALL"
        >
          <span class="no-wrap">{{ t("actions.showDetailPage") }}</span>
        </Btn>
      </template>
      <template #empty>
        <Empty :name="t('models.name')" inline />
      </template>
    </BaseTable>
  </div>
</template>
