<script lang="ts">
export default {
  name: "ModelsTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ModelContextMenu from "@/frontend/components/Models/ContextMenu/index.vue";
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { type Model } from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import {
  useModelsStore,
  ModelTableViewColsEnum,
} from "@/frontend/stores/models";

type Props = {
  models: Model[];
  editable?: boolean;
  wishlist?: boolean;
  loading?: boolean;
  emptyBoxVisible?: boolean;
};

defineProps<Props>();

const { t, toNumber, toUEC, toDollar } = useI18n();

const updating = ref(false);

const mobile = useMobile();

const modelsStore = useModelsStore();

type ShipTableCol = {
  name: ModelTableViewColsEnum;
  label: string;
  sortable?: boolean;
};

const extraColumns = computed<ShipTableCol[]>(() => {
  return Object.values(ModelTableViewColsEnum)
    .map((col) => {
      return {
        name: col,
        label: t(`labels.models.table.columns.${col}`),
        sortable: true,
      };
    })
    .filter((col) => {
      return modelsStore.tableViewCols.includes(col.name);
    });
});

const manufacturerColumnVisible = computed(() => {
  return extraColumns.value.some(
    (column) => column.name === "manufacturer_name",
  );
});

const tableColumns = computed<BaseTableColumn[]>(() => {
  return [
    {
      name: "store_image",
      label: "",
      centered: true,
    },
    {
      name: "name",
      label: t("labels.vehicle.name"),
      width: "40%",
      sortable: true,
    },
    ...extraColumns.value,
  ];
});
</script>

<template>
  <div>
    <BaseTable
      :records="models"
      primary-key="slug"
      default-sort="name asc"
      :columns="tableColumns"
      :loading="loading"
      :empty-box-visible="emptyBoxVisible"
    >
      <template #col-store_image="{ record }">
        <ViewImage
          :image="record.media.storeImage"
          size="small"
          alt="image"
          :variant="LazyImageVariantsEnum.WIDE"
          shadow
        />
      </template>
      <template #col-manufacturer_name="{ record }">
        {{ record.manufacturer?.name }}
      </template>
      <template #col-length="{ record }">
        <span class="no-break">{{
          toNumber(record.metrics.length || "", "distance")
        }}</span>
      </template>
      <template #col-beam="{ record }">
        <span class="no-break">{{
          toNumber(record.metrics.beam || "", "distance")
        }}</span>
      </template>
      <template #col-height="{ record }">
        <span class="no-break">{{
          toNumber(record.metrics.height || "", "distance")
        }}</span>
      </template>
      <template #col-mass="{ record }">
        <span class="no-break">{{
          toNumber(record.metrics.mass || "", "weight")
        }}</span>
      </template>
      <template #col-cargo="{ record }">
        <span class="no-break">{{
          toNumber(record.metrics.cargo || "", "cargo")
        }}</span>
      </template>
      <template #col-hydrogen_fuel_tank_size="{ record }">
        <span class="no-break">{{
          toNumber(record.metrics.hydrogenFuelTankSize || "", "cargo")
        }}</span>
      </template>
      <template #col-quantum_fuel_tank_size="{ record }">
        <span class="no-break">{{
          toNumber(record.metrics.quantumFuelTankSize || "", "cargo")
        }}</span>
      </template>
      <template #col-min_crew="{ record }">
        <span class="no-break">{{
          toNumber(record.crew.min || "", "people")
        }}</span>
      </template>
      <template #col-max_crew="{ record }">
        <span class="no-break">{{
          toNumber(record.crew.max || "", "people")
        }}</span>
      </template>
      <template #col-ground_max_speed="{ record }">
        <span class="no-break">{{
          toNumber(record.speeds.groundMaxSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-scm_speed="{ record }">
        <span class="no-break">{{
          toNumber(record.speeds.scmSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-max_speed="{ record }">
        <span class="no-break">{{
          toNumber(record.speeds.maxSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-production_status="{ record }">
        {{ t(`labels.model.productionStatus.${record.productionStatus}`) }}
      </template>
      <template #col-price="{ record }">
        <!-- eslint-disable vue/no-v-html -->
        <div
          v-tooltip="{ content: toUEC(record.price), html: true }"
          class="no-break"
          v-html="toUEC(record.price)"
        />
        <!-- eslint-enable vue/no-v-html -->
      </template>
      <template #col-pledge_price="{ record }">
        <span class="no-break">{{ toDollar(record.pledgePrice) }}</span>
      </template>
      <template #col-name="{ record }">
        <div class="name">
          <router-link
            :to="{
              name: 'ship',
              params: {
                slug: record.slug,
              },
            }"
          >
            {{ record.name }}
          </router-link>
          <br />
          <small>
            <!-- eslint-disable vue/no-v-html -->
            <span
              v-if="record.manufacturer && !manufacturerColumnVisible"
              v-html="record.manufacturer.name"
            />
          </small>
        </div>
      </template>
      <template #actions="{ record }">
        <BtnGroup inline class="vehicles-table-btn-group">
          <Btn
            v-if="!mobile"
            :to="{
              name: 'ship',
              params: {
                slug: record.slug,
              },
            }"
            :size="BtnSizesEnum.SMALL"
          >
            <span>{{ t("actions.showDetailPage") }}</span>
          </Btn>
          <AddToHangar :model="record" :size="BtnSizesEnum.SMALL" />
          <ModelContextMenu :model="record" />
        </BtnGroup>
      </template>
      <template #empty>
        <Empty :name="t('models.name')" />
      </template>
    </BaseTable>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
