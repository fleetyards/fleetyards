<script lang="ts">
export default {
  name: "VehiclesTable",
};
</script>

<script lang="ts" setup>
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import BaseTable from "@/shared/components/base/Table/index.vue";
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import VehicleContextMenu from "@/frontend/components/Vehicles/ContextMenu/index.vue";
import HangarGroups from "@/frontend/components/Vehicles/HangarGroups/index.vue";
import HangarEmpty from "@/frontend/components/Hangar/Empty/index.vue";
import ListActions from "@/frontend/components/Vehicles/Table/ListActions.vue";
import VehicleStates from "@/frontend/components/Vehicles/Table/States.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { fociText } from "@/shared/utils/Foci";
import { useVehicleCargo } from "@/frontend/composables/useVehicleCargo";
import { FeatureFlagName, type Vehicle } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useFeatures } from "@/frontend/composables/useFeatures";

import {
  type BaseTableCol,
  BaseTableColAlignmentEnum,
} from "@/shared/components/base/Table/types";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import {
  useHangarStore,
  HangarTableViewColsEnum,
  HangarTableViewImageColsEnum,
} from "@/frontend/stores/hangar";
import {
  useWishlistStore,
  WishlistTableViewColsEnum,
  WishlistTableViewImageColsEnum,
} from "@/frontend/stores/wishlist";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import { formatWeaponSizes } from "@/frontend/utils/weaponSizes";

type Props = {
  vehicles: Vehicle[];
  editable?: boolean;
  wishlist?: boolean;
  loading?: boolean;
  emptyVisible?: boolean;
  // Draws a grip beside each name and lets the rows be dragged by it.
  sortable?: boolean;
  // Off where the list's toolbar carries the select-all box and the bulk
  // actions; the page then binds `selected` to hand them the picked rows.
  selectionControls?: boolean;
  highlightedGroupId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  selectionControls: true,
  highlightedGroupId: undefined,
});

const emit = defineEmits<{
  sort: [keys: string[], moved: string];
  // One place up or down, from the grip's arrow keys.
  move: [id: string, offset: number];
  openGuide: [];
}>();

const { t, toNumber, toUEC, toDollar } = useI18n();

const { cargoLabel } = useVehicleCargo();

// Held here unless the page binds it: a table on its own keeps its selection
// to itself, a table under a toolbar shares it.
const selected = defineModel<string[]>("selected", { default: () => [] });

const hangarStore = useHangarStore();
const wishlistStore = useWishlistStore();

const { isFeatureEnabled } = useFeatures();

// Like the panel's title: the owner's own ship opens on its overview, a loaner
// and anyone else's ship on the model.
const toVehicle = useVehicleRoute();

const hasOverview = (record: Vehicle) =>
  props.editable &&
  !record.loaner &&
  isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW);

const nameRoute = (record: Vehicle) => {
  if (hasOverview(record)) {
    return toVehicle("hangar-vehicle-overview", record);
  }

  return { name: "ship", params: { slug: record.model.slug } };
};

const extraColumns = computed(() => {
  if (props.wishlist) {
    return Object.values(WishlistTableViewColsEnum)
      .map((col) => {
        return {
          name: col,
          label: t(`labels.hangarTable.columns.${col}`),
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
      };
    })
    .filter((col) => {
      return hangarStore.tableViewCols.includes(col.name);
    });
});

const extraImageColumns = computed<BaseTableCol<Vehicle>[]>(() => {
  if (props.wishlist) {
    return Object.values(WishlistTableViewImageColsEnum)
      .map((col) => {
        return {
          name: col,
          label: "",
          centered: true,
        };
      })
      .filter((col) => {
        return wishlistStore.tableViewImageCols.includes(col.name);
      });
  }

  return Object.values(HangarTableViewImageColsEnum)
    .map((col) => {
      return {
        name: col,
        label: "",
        width: col.endsWith("Wide") ? "270px" : "120px",
        centered: true,
      };
    })
    .filter((col) => {
      return hangarStore.tableViewImageCols.includes(col.name);
    });
});

// The same two tones a card's caps take in the grid, and the same precedence:
// the hovered group wins, or a flagship in it would be the one row whose
// membership you cannot read.
const rowClass = (record: Vehicle) => {
  const highlighted =
    !!props.highlightedGroupId &&
    record.hangarGroupIds.includes(props.highlightedGroupId);

  return {
    "vehicles-table-row--highlight": highlighted,
    "vehicles-table-row--flagship":
      !highlighted && !!record.flagship && !props.wishlist,
  };
};

const manufacturerColumnVisible = computed(() => {
  return extraColumns.value.some(
    (column) => column.name === "modelManufacturerName",
  );
});

// No column sorts from its heading: the list toolbar above the table is the
// sort control in both views.
const tableColumns = computed<BaseTableCol<Vehicle>[]>(() => {
  return [
    // First after the box, where a row's handle is looked for, and apart from
    // the name so a grab never lands on its link.
    ...(props.sortable
      ? [
          {
            name: "grip",
            label: "",
            width: "40px",
            alignment: BaseTableColAlignmentEnum.CENTER,
          },
        ]
      : []),
    ...extraImageColumns.value,
    {
      name: "name",
      label: t("labels.vehicle.name"),
      width: "40%",
    },
    ...extraColumns.value,
    {
      name: "states",
      label: t("labels.vehicle.states"),
      width: "110px",
      alignment: BaseTableColAlignmentEnum.RIGHT,
      mobile: false,
    },
    {
      name: "groups",
      label: t("labels.vehicle.hangarGroups"),
      width: "120px",
      mobile: false,
    },
  ];
});

const comlink = useComlink();

const hangarDeleteAllComlink = ref();

onMounted(() => {
  hangarDeleteAllComlink.value = comlink.on("hangar-delete-all", resetSelected);
});

onBeforeUnmount(() => {
  hangarDeleteAllComlink.value();
});

const { openEditModal: openVehicleEdit } = useVehicleModals();

const openEditModal = (vehicle: Vehicle) =>
  openVehicleEdit(vehicle, { wishlist: props.wishlist });

const storeImage = (record: Vehicle) => {
  if (record && record.image) {
    return record.image;
  }

  if (record && record.upgrade) {
    return record.upgrade.media.storeImage;
  }

  return record.model.media.storeImage;
};

const angledImage = (record: Vehicle) => {
  if (record && record.model.media.angledViewColored) {
    return record.model.media.angledViewColored;
  }

  return record.model.media.angledView;
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
      :empty-visible="emptyVisible"
      :sortable="sortable"
      sort-handle=".vehicles-table-grip"
      :selection-controls="selectionControls"
      :row-class="rowClass"
      @selected-change="onSelectedChange"
      @sort="(keys, moved) => emit('sort', keys, moved)"
    >
      <template #selected-actions>
        <ListActions :selected="selected" :wishlist="wishlist" />
      </template>
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
      <template #col-grip="{ record }">
        <button
          v-tooltip="t('actions.reorder')"
          type="button"
          class="vehicles-table-grip"
          :aria-label="t('actions.reorder')"
          aria-keyshortcuts="ArrowUp ArrowDown ArrowLeft ArrowRight"
          data-test="vehicles-table-grip"
          @keydown.up.prevent="emit('move', record.id, -1)"
          @keydown.left.prevent="emit('move', record.id, -1)"
          @keydown.down.prevent="emit('move', record.id, 1)"
          @keydown.right.prevent="emit('move', record.id, 1)"
        >
          <i class="fa-duotone fa-grip-vertical" />
        </button>
      </template>
      <template #col-name="{ record, mobile }">
        <div class="name">
          <router-link
            :to="nameRoute(record)"
            data-test="vehicle-table-name"
            :data-tour="hasOverview(record) ? 'vehicle-overview' : undefined"
          >
            <CatalogueItemPopover
              :item="{
                type: 'Model',
                slug: record.model.slug,
                name: record.model.name,
              }"
              :record="record.model"
              :link="false"
              :focusable="false"
            >
              <span v-if="record.name">
                {{ record.name }}
              </span>

              <span v-else>{{ record.model.name }}</span>
            </CatalogueItemPopover>
          </router-link>
          <i
            v-if="record.flagship && !wishlist"
            v-tooltip="t('labels.vehicle.flagship')"
            class="fa fa-certificate vehicles-table-flagship"
            data-test="vehicle-table-flagship"
          />
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
          <div v-if="mobile" class="vehicles-table-mobile-meta">
            <VehicleStates :vehicle="record" :wishlist="wishlist" compact />
            <HangarGroups
              v-if="record.hangarGroups.length"
              :groups="record.hangarGroups"
              :highlighted-id="highlightedGroupId"
              stacked
            />
          </div>
        </div>
      </template>
      <template #col-modelManufacturerName="{ record }">
        {{ record.model.manufacturer?.name }}
      </template>
      <template #col-modelLength="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.length || "", "distance")
        }}</span>
      </template>
      <template #col-modelBeam="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.beam || "", "distance")
        }}</span>
      </template>
      <template #col-modelHeight="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.height || "", "distance")
        }}</span>
      </template>
      <template #col-modelMass="{ record }">
        <span class="no-break">{{
          toNumber(record.model.metrics.mass || "", "weight")
        }}</span>
      </template>
      <template #col-modelCargo="{ record }">
        <span class="no-break">{{ cargoLabel(record) }}</span>
      </template>
      <template #col-maxWeaponSize="{ record }">
        <span class="no-break">{{
          formatWeaponSizes(record.weaponSizes)
        }}</span>
      </template>
      <template #col-modelCrew="{ record }">
        <span class="no-break">{{
          toNumber(record.model.crew.value || "", "people")
        }}</span>
      </template>
      <template #col-modelGroundMaxSpeed="{ record }">
        <span class="no-break">{{
          toNumber(record.model.speeds.groundMaxSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-modelScmSpeed="{ record }">
        <span class="no-break">{{
          toNumber(record.model.speeds.scmSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-modelMaxSpeed="{ record }">
        <span class="no-break">{{
          toNumber(record.model.speeds.maxSpeed || "", "speed")
        }}</span>
      </template>
      <template #col-modelProductionStatus="{ record }">
        {{
          t(`labels.model.productionStatus.${record.model.productionStatus}`)
        }}
      </template>
      <template #col-modelFocus="{ record }">
        {{ fociText(record.model, t("labels.model.stealth")) }}
      </template>
      <template #col-modelPrice="{ record }">
        <!-- eslint-disable vue/no-v-html -->
        <div
          v-tooltip="{ content: toUEC(record.model.price), html: true }"
          class="no-break"
          v-html="toUEC(record.model.price)"
        />
        <!-- eslint-enable vue/no-v-html -->
      </template>
      <template #col-modelPledgePrice="{ record }">
        <span class="no-break">{{ toDollar(record.model.pledgePrice) }}</span>
      </template>
      <template #col-states="{ record }">
        <VehicleStates :vehicle="record" :wishlist="wishlist" />
      </template>
      <template #col-groups="{ record }">
        <HangarGroups
          :groups="record.hangarGroups"
          :highlighted-id="highlightedGroupId"
          stacked
        />
      </template>
      <template #actions="{ record }">
        <BtnGroup class="vehicles-table-btn-group">
          <Btn
            v-if="record && editable && !record.loaner"
            :aria-label="t('actions.edit')"
            data-test="vehicle-edit"
            @click="openEditModal(record)"
          >
            <i class="fa-duotone fa-pen-to-square" />
            {{ t("actions.edit") }}
          </Btn>
          <VehicleContextMenu
            :vehicle="record"
            :editable="editable && !record.loaner"
            :wishlist="wishlist"
            hide-edit
            data-tour="vehicle-menu"
          />
        </BtnGroup>
      </template>
      <template #empty>
        <HangarEmpty
          :wishlist="wishlist"
          :guide="editable && !wishlist"
          @open-guide="emit('openGuide')"
        />
      </template>
    </BaseTable>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
