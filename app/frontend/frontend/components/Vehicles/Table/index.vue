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
import HangarEmptyTable from "@/frontend/components/HangarEmptyTable/index.vue";
import WishlistEmptyTable from "@/frontend/components/WishlistEmptyTable/index.vue";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";

type Props = {
  vehicles: Vehicle[];
  editable?: boolean;
  wishlist?: boolean;
  loading?: boolean;
  emptyBoxVisible?: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayConfirm } = useNoty();

const selected = ref<string[]>([]);

const deleting = ref(false);

const updating = ref(false);

const extraColumns = computed(() => {
  return [
    {
      name: "model_manufacturer_name",
      label: t("labels.model.manufacturer"),
      sortable: true,
      mobile: false,
    },
  ];
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
  comlink.on("vehicles-delete-all", resetSelected);
});

onBeforeUnmount(() => {
  comlink.off("vehicles-delete-all", resetSelected);
});

const openBulkGroupEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/BulkGroupModal/index.vue"),
    props: {
      vehicleIds: selected.value,
    },
  });
};

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

const addToWishlistBulk = async () => {
  updating.value = true;

  await await vehiclesCollection.addToWishlistBulk(selected.value);

  resetSelected();

  updating.value = false;
};

const addToHangarBulk = async () => {
  updating.value = true;

  await vehiclesCollection.addToHangarBulk(selected.value);

  wishlistCollection.refresh();

  resetSelected();

  updating.value = false;
};

const hideFromPublicHangar = async () => {
  updating.value = true;

  await vehiclesCollection.hideFromPublicHangar(selected.value);

  wishlistCollection.refresh();

  updating.value = false;
};

const showOnPublicHangar = async () => {
  updating.value = true;

  await vehiclesCollection.showOnPublicHangar(selected.value);

  wishlistCollection.refresh();

  updating.value = false;
};

const onSelectedChange = (value) => {
  selected.value = value;
};

const destroyBulk = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.hangar.destroySelected"),
    onConfirm: async () => {
      await vehiclesCollection.destroyBulk(selected.value);

      wishlistCollection.refresh();

      resetSelected();

      deleting.value = false;
    },
    onClose: () => {
      deleting.value = false;
    },
  });
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
        <BtnGroup inline>
          <span>{{ t("labels.public") }}</span>
          <Btn
            v-tooltip="t('actions.hangar.showOnPublicHangar')"
            :size="BtnSizesEnum.SMALL"
            :disabled="updating"
            @click="showOnPublicHangar"
          >
            <i class="fad fa-eye" />
          </Btn>
          <Btn
            v-tooltip="t('actions.hangar.hideFromPublicHangar')"
            :size="BtnSizesEnum.SMALL"
            :disabled="updating"
            @click="hideFromPublicHangar"
          >
            <i class="fad fa-eye-slash" />
          </Btn>
        </BtnGroup>
        <Btn
          v-if="wishlist"
          :size="BtnSizesEnum.SMALL"
          :disabled="updating"
          inline
          @click="addToHangarBulk"
        >
          {{ t("actions.addToHangar") }}
        </Btn>
        <Btn
          v-else
          :size="BtnSizesEnum.SMALL"
          :disabled="updating"
          inline
          @click="addToWishlistBulk"
        >
          {{ t("actions.addToWishlist") }}
        </Btn>
        <Btn
          v-if="!wishlist"
          :size="BtnSizesEnum.SMALL"
          inline
          @click="openBulkGroupEditModal"
        >
          {{ t("actions.hangar.editGroupsSelected") }}
        </Btn>
        <Btn
          v-tooltip="t('actions.deleteSelected')"
          :size="BtnSizesEnum.SMALL"
          :disabled="deleting"
          inline
          @click="destroyBulk"
        >
          <i class="fal fa-trash" />
        </Btn>
      </template>
      <template #col-store_image="{ record }">
        <LazyImage
          :variant="LazyImageVariantsEnum.WIDE"
          :src="storeImage(record)"
          alt="storeImage"
          shadow
        />
      </template>
      <template #col-model_manufacturer_name="{ record }">
        {{ record.model.manufacturer?.name }}
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
        <WishlistEmptyTable v-if="wishlist" />
        <HangarEmptyTable v-else />
      </template>
    </BaseTable>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
