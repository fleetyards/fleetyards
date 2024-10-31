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
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import { useModelsStore } from "@/frontend/stores/models";
import { TableViewColsEnum } from "@/frontend/types";

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
  name: TableViewColsEnum;
  label: string;
  sortable?: boolean;
};

const extraColumns = computed<ShipTableCol[]>(() => {
  return [
    {
      name: TableViewColsEnum.MANUFACTURER_NAME,
      label: t("labels.model.manufacturer"),
      sortable: true,
    },
    {
      name: TableViewColsEnum.LENGTH,
      label: t("model.length"),
      sortable: true,
    },
    {
      name: TableViewColsEnum.BEAM,
      label: t("model.beam"),
      sortable: true,
    },
    {
      name: TableViewColsEnum.HEIGHT,
      label: t("model.height"),
      sortable: true,
    },
    {
      name: TableViewColsEnum.MASS,
      label: t("model.mass"),
      sortable: true,
    },
    {
      name: TableViewColsEnum.CARGO,
      label: t("model.cargo"),
      sortable: true,
    },
    {
      name: TableViewColsEnum.PRICE,
      label: t("model.price"),
      sortable: true,
    },
    {
      name: TableViewColsEnum.PLEDGE_PRICE,
      label: t("model.pledgePrice"),
      sortable: true,
    },
  ].filter((col) => {
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

const storeImage = (record: Model) => {
  return record.media.storeImage?.medium;
};
</script>

<template>
  <div>
    <BaseTable
      :records="models"
      primary-key="slug"
      :columns="tableColumns"
      :loading="loading"
      :empty-box-visible="emptyBoxVisible"
    >
      <template #col-store_image="{ record }">
        <LazyImage
          :variant="LazyImageVariantsEnum.WIDE"
          :src="storeImage(record)"
          alt="storeImage"
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
