<template>
  <div>
    <FilteredTable
      :records="vehicles"
      :primary-key="primaryKey"
      :columns="tableColumns"
      :selectable="editable"
      :selected="selected"
      :empty-box-visible="!vehicles.length"
      @selected-change="onSelectedChange"
    >
      <template #selected-actions>
        <div class="d-flex">
          <BtnGroup :inline="true">
            <span>{{ t("labels.public") }}</span>
            <Btn
              v-tooltip="t('actions.hangar.showOnPublicHangar')"
              size="small"
              variant="dropdown"
              :disabled="updating"
              in-group
              @click="showOnPublicHangar"
            >
              <i class="fad fa-eye" />
            </Btn>
            <Btn
              v-tooltip="t('actions.hangar.hideFromPublicHangar')"
              size="small"
              variant="dropdown"
              :disabled="updating"
              in-group
              @click="hideFromPublicHangar"
            >
              <i class="fad fa-eye-slash" />
            </Btn>
          </BtnGroup>
          <Btn
            v-if="wishlist"
            size="small"
            :inline="true"
            :disabled="updating"
            @click="addToHangarBulk"
          >
            {{ t("actions.addToHangar") }}
          </Btn>
          <Btn
            v-else
            size="small"
            :inline="true"
            :disabled="updating"
            @click="addToWishlistBulk"
          >
            {{ t("actions.addToWishlist") }}
          </Btn>
          <Btn
            v-if="!wishlist"
            size="small"
            :inline="true"
            @click="openBulkGroupEditModal"
          >
            {{ t("actions.hangar.editGroupsSelected") }}
          </Btn>
          <Btn
            v-tooltip="t('actions.deleteSelected')"
            size="small"
            :inline="true"
            :disabled="deleting"
            @click="destroyBulk"
          >
            <i class="fal fa-trash" />
          </Btn>
        </div>
      </template>
      <template #col-store_image="{ record }">
        <div
          :key="storeImage(record)"
          v-lazy:background-image="storeImage(record)"
          class="image lazy"
          alt="storeImage"
        />
      </template>
      <template #col-name="{ record }">
        <div class="name">
          <router-link
            :to="{
              name: 'model',
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
            <span v-html="record.model.manufacturer.name" />
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
      <template #col-actions="{ record }">
        <BtnGroup :inline="true" class="vehicles-table-btn-group">
          <Btn
            v-if="record && editable && !record.loaner"
            :aria-label="t('actions.edit')"
            size="small"
            data-test="vehicle-edit"
            :inline="true"
            variant="link"
            in-group
            @click="openEditModal(record)"
          >
            {{ t("actions.edit") }}
          </Btn>
          <VehicleContextMenu
            :vehicle="record"
            :editable="editable && !record.loaner"
            :wishlist="wishlist"
            :hide-edit="true"
            in-group
          />
        </BtnGroup>
      </template>
      <template #empty>
        <WishlistEmptyTable v-if="wishlist" />
        <HangarEmptyTable v-else />
      </template>
    </FilteredTable>
  </div>
</template>

<script lang="ts" setup>
// import vehiclesCollection from "@/frontend/api/collections/Vehicles";
// import wishlistCollection from "@/frontend/api/collections/Wishlist";
import FilteredTable from "@/shared/components/FilteredTable/index.vue";
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

type Props = {
  vehicles: Vehicle[];
  primaryKey: string;
  editable?: boolean;
  wishlist?: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayConfirm } = useNoty(t);

const selected = ref<string[]>([]);

const deleting = ref(false);

const updating = ref(false);

const tableColumns: FilteredTableColumn[] = [
  {
    name: "store_image",
    class: "store-image wide",
    type: "store-image",
  },
  {
    name: "name",
    width: "40%",
  },
  {
    name: "states",
    width: "10%",
  },
  {
    name: "groups",
    label: t("labels.vehicle.hangarGroups"),
    width: "10%",
  },
  { name: "actions", label: t("labels.actions"), minWidth: "140px" },
];

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

const openEditModal = (vehicle) => {
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
    return record.paint.storeImageSmall;
  }

  if (record && record.upgrade) {
    return record.upgrade.storeImageMedium;
  }

  return record.model.storeImageMedium;
};

const addToWishlistBulk = async () => {
  updating.value = true;

  await vehiclesCollection.addToWishlistBulk(selected.value);

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

<script lang="ts">
export default {
  name: "VehiclesTable",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
