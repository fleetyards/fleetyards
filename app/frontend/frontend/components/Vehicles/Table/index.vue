<script lang="ts">
export default {
  name: "VehiclesTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import VehicleContextMenu from "@/frontend/components/Vehicles/ContextMenu/index.vue";
import HangarGroups from "@/frontend/components/Vehicles/HangarGroups/index.vue";
import VehiclesEmpty from "@/frontend/components/Vehicles/Empty/index.vue";
import ListActions from "@/frontend/components/Vehicles/Table/ListActions.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import {
  useHangarStore,
  HangarTableViewColsEnum,
} from "@/frontend/stores/hangar";
import {
  useWishlistStore,
  WishlistTableViewColsEnum,
} from "@/frontend/stores/wishlist";

type Props = {
  vehicles: Vehicle[];
  editable?: boolean;
  wishlist?: boolean;
  loading?: boolean;
  emptyBoxVisible?: boolean;
};

const props = defineProps<Props>();

const { t, toNumber, toUEC, toDollar } = useI18n();

const selected = ref<string[]>([]);

const hangarStore = useHangarStore();
const wishlistStore = useWishlistStore();

const extraColumns = computed(() => {
  if (props.wishlist) {
    return Object.values(WishlistTableViewColsEnum)
      .map((col) => {
        return {
          name: col,
          label: t(`labels.hangarTable.columns.${col}`),
          sortable: true,
        };
      })
      .filter((col) => {
        return wishlistStore.tableViewCols.includes(col.name);
      });
  }

  return Object.values(HangarTableViewColsEnum)
    .map((col) => {
      return {
        name: col,
        label: t(`labels.hangarTable.columns.${col}`),
        sortable: true,
      };
    })
    .filter((col) => {
      return hangarStore.tableViewCols.includes(col.name);
    });
});

const manufacturerColumnVisible = computed(() => {
  return extraColumns.value.some(
    (column) => column.name === "model_manufacturer_name",
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
    {
      name: "states",
      label: t("labels.vehicle.states"),
      width: "10%",
      mobile: false,
    },
    {
      name: "groups",
      label: t("labels.vehicle.hangarGroups"),
      width: "10%",
      mobile: false,
    },
  ];
});

const comlink = useComlink();

onMounted(() => {
  comlink.on("hangar-delete-all", resetSelected);
});

onBeforeUnmount(() => {
  comlink.off("hangar-delete-all", resetSelected);
});

const openEditModal = (vehicle: Vehicle) => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/Vehicles/Modal/index.vue"),
    props: {
      vehicle,
      wishlist: props.wishlist,
    },
  });
};

const storeImage = (record: Vehicle) => {
  if (record && record.paint) {
    return record.paint.media.storeImage?.medium;
  }

  if (record && record.upgrade) {
    return record.upgrade.media.storeImage?.medium;
  }

  return record.model.media.storeImage?.medium;
};

const onSelectedChange = (value: string[]) => {
  selected.value = value;
};

const resetSelected = () => {
  selected.value = [];
};
</script>

<template>
  <div>
    <BaseTable
      :records="vehicles"
      primary-key="id"
      :columns="tableColumns"
      :selectable="editable"
      :selected="selected"
      :loading="loading"
      :empty-box-visible="emptyBoxVisible"
      @selected-change="onSelectedChange"
    >
      <template #selected-actions>
        <ListActions :selected="selected" :wishlist="wishlist" />
      </template>
      <template #col-store_image="{ record }">
        <LazyImage
          :variant="LazyImageVariantsEnum.WIDE"
          :src="storeImage(record)"
          alt="storeImage"
          shadow
        />
      </template>
      <template #col-name="{ record }">
        <div class="name">
          <router-link
            :to="{
              name: 'ship',
              params: {
                slug: record.model.slug,
              },
            }"
          >
            <span v-if="record.name">
              {{ record.name }}
            </span>

            <span v-else>{{ record.model.name }}</span>
          </router-link>
          <br />
          <small>
            <!-- eslint-disable vue/no-v-html -->
            <span
              v-if="record.model.manufacturer && !manufacturerColumnVisible"
              v-html="record.model.manufacturer.name"
            />
            <template v-if="record.name">
              {{ record.model.name }}
            </template>
          </small>
        </div>
      </template>
      <template #col-model_manufacturer_name="{ record }">
        {{ record.model.manufacturer?.name }}
      </template>
      <template #col-model_length="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.length || "", "distance")
        }}</span>
      </template>
      <template #col-model_beam="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.beam || "", "distance")
        }}</span>
      </template>
      <template #col-model_height="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.height || "", "distance")
        }}</span>
      </template>
      <template #col-model_mass="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.mass || "", "weight")
        }}</span>
      </template>
      <template #col-model_cargo="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.cargo || "", "cargo")
        }}</span>
      </template>
      <template #col-model_min_crew="{ record }">
        <span class="no-break">{{
          toNumber(record.model.crew.min || "", "people")
        }}</span>
      </template>
      <template #col-model_max_crew="{ record }">
        <span class="no-break">{{
          toNumber(record.model.crew.max || "", "people")
        }}</span>
      </template>
      <template #col-model_ground_max_speed="{ record }">
        <span class="no-break">{{
          toNumber(record.model.speeds.groundMaxSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-model_scm_speed="{ record }">
        <span class="no-break">{{
          toNumber(record.model.speeds.scmSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-model_max_speed="{ record }">
        <span class="no-break">{{
          toNumber(record.model.speeds.maxSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-model_production_status="{ record }">
        {{
          t(`labels.model.productionStatus.${record.model.productionStatus}`)
        }}
      </template>
      <template #col-model_focus="{ record }">
        {{ record.model.focus }}
      </template>
      <template #col-model_price="{ record }">
        <!-- eslint-disable vue/no-v-html -->
        <div
          v-tooltip="{ content: toUEC(record.model.price), html: true }"
          class="no-break"
          v-html="toUEC(record.model.price)"
        />
        <!-- eslint-enable vue/no-v-html -->
      </template>
      <template #col-model_pledge_price="{ record }">
        <span class="no-break">{{ toDollar(record.model.pledgePrice) }}</span>
      </template>
      <template #col-states="{ record }">
        <div class="vehicle-states">
          <i
            v-if="record.flagship && !wishlist"
            v-tooltip="t('labels.vehicle.flagship')"
            class="fa fa-certificate flagship-icon"
          />
          <i
            v-if="record.model.onSale"
            v-tooltip="t('labels.model.onSale')"
            class="fad fa-dollar-sign on-sale"
          />
          <i
            v-if="record.public && record.nameVisible"
            v-tooltip="t('labels.vehicle.fullPublic')"
            class="fad fa-eye-evil full-public-icon"
          />
          <i
            v-else-if="record.public"
            v-tooltip="t('labels.vehicle.public')"
            class="fad fa-eye"
          />
          <i
            v-if="wishlist && record.saleNotify"
            v-tooltip="t('labels.vehicle.saleNotify')"
            class="fad fa-bell"
          />
        </div>
      </template>
      <template #col-groups="{ record }">
        <HangarGroups :groups="record.hangarGroups" size="large" />
      </template>
      <template #actions="{ record }">
        <BtnGroup inline class="vehicles-table-btn-group">
          <Btn
            v-if="record && editable && !record.loaner"
            :aria-label="t('actions.edit')"
            :size="BtnSizesEnum.SMALL"
            data-test="vehicle-edit"
            @click="openEditModal(record)"
          >
            <i class="fad fa-pen-to-square" />
            {{ t("actions.edit") }}
          </Btn>
          <VehicleContextMenu
            :vehicle="record"
            :editable="editable && !record.loaner"
            :wishlist="wishlist"
            hide-edit
          />
        </BtnGroup>
      </template>
      <template #empty>
        <VehiclesEmpty :wishlist="wishlist" />
      </template>
    </BaseTable>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
