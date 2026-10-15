<script lang="ts">
export default {
  name: "VehicleContextMenu",
};
</script>

<script lang="ts" setup>
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FeatureFlagName,
  VehicleLoadoutKindEnum,
  type Vehicle,
} from "@/services/fyApi";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useLoadoutEditor } from "@/frontend/composables/useLoadoutEditor";

type Props = {
  vehicle: Vehicle;
  editable?: boolean;
  hideEdit?: boolean;
  onVehiclePage?: boolean;
  // Where the page links the ship database itself, as the overview's hero does.
  hideShipPage?: boolean;
  wishlist?: boolean;
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  hideEdit: false,
  onVehiclePage: false,
  hideShipPage: false,
  wishlist: false,
  variant: undefined,
  size: undefined,
  inGroup: false,
});

const { t } = useI18n();

const { isFeatureEnabled } = useFeatures();

const deleting = ref(false);

const updating = ref(false);

const { loadoutEditorAvailable } = useLoadoutEditor();

// The owner edits the ship's loadout where the editor is available; anyone
// else, or anyone looking at a loaner, a wishlist ship or one that is not flight
// ready, looks at the one that is active, as the panel's loadout marker does.
const loadoutEditable = computed(
  () =>
    props.editable &&
    !props.wishlist &&
    !props.vehicle?.wanted &&
    !props.vehicle?.loaner &&
    loadoutEditorAvailable(props.vehicle),
);

const loadoutVisible = computed(() => {
  if (!props.vehicle) {
    return false;
  }

  if (!loadoutEditable.value) {
    return (
      props.vehicle.activeLoadout?.kind === VehicleLoadoutKindEnum.FLEETYARDS
    );
  }

  return !!props.vehicle.model.hasModules;
});

const { useUpdateMutation, useDestroyMutation } = useVehicleMutations();

const vehicle = computed(() => props.vehicle);

const updateMutation = useUpdateMutation(vehicle);

const addToWishlist = async () => {
  if (!props.vehicle) {
    return;
  }

  updating.value = true;

  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      data: {
        wanted: true,
      },
    })
    .then(() => {
      comlink.emit("vehicle-save", props.vehicle.id);
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      updating.value = false;
    });
};

const addToHangar = async () => {
  if (!props.vehicle) {
    return;
  }

  updating.value = true;

  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      data: {
        wanted: false,
      },
    })
    .then(() => {
      comlink.emit("vehicle-save", props.vehicle.id);
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      updating.value = false;
    });
};

const hideable = computed(
  () =>
    props.editable &&
    !props.onVehiclePage &&
    !props.wishlist &&
    !props.vehicle.loaner &&
    !props.vehicle.bundled,
);

const toggleHidden = async () => {
  updating.value = true;

  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      data: {
        hiddenByUser: !props.vehicle.hiddenByUser,
      },
    })
    .then(() => {
      comlink.emit("vehicle-save", props.vehicle.id);
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      updating.value = false;
    });
};

const { displayConfirm } = useAppNotifications();

const remove = () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.vehicle.destroy"),
    onConfirm: async () => {
      await destroy();
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};

const destroyMutation = useDestroyMutation(vehicle);

const destroy = async () => {
  if (!props.vehicle) {
    return;
  }

  await destroyMutation
    .mutateAsync({
      id: props.vehicle.id,
    })
    .then(() => {
      comlink.emit("vehicle-destroy", props.vehicle.id);
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      deleting.value = false;
    });
};

const comlink = useComlink();

const { openEditModal, openLoadoutModal, openLoadoutView } = useVehicleModals();

const openEdit = () => {
  openEditModal(props.vehicle, { wishlist: props.wishlist });
};

const openLoadout = () => {
  if (loadoutEditable.value) {
    openLoadoutModal(props.vehicle, { editable: true });
  } else {
    openLoadoutView(props.vehicle);
  }
};

const vehicleOverviewVisible = computed(
  () => props.editable && isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW),
);

// The vehicle page carries these as tabs and header buttons already.
const pageShortcutsVisible = computed(
  () => vehicleOverviewVisible.value && !props.onVehiclePage,
);

// A wishlist ship takes no new log entries.
const logVisible = computed(
  () => pageShortcutsVisible.value && !props.wishlist,
);

const toVehicle = useVehicleRoute();

const logRoute = computed(() => toVehicle("hangar-vehicle-log", props.vehicle));

const loadoutsRoute = computed(() =>
  toVehicle("hangar-vehicle-loadouts", props.vehicle),
);

const cargoRoute = computed(() =>
  toVehicle("hangar-vehicle-cargo", props.vehicle),
);

const loadoutsVisible = computed(
  () => props.editable && !props.onVehiclePage && props.vehicle.model?.inGame,
);

const cargoVisible = computed(
  () =>
    props.editable &&
    !props.onVehiclePage &&
    !props.wishlist &&
    props.vehicle.model?.inGame &&
    isFeatureEnabled(FeatureFlagName.SHIP_INVENTORIES),
);

const shipPageVisible = computed(
  () => !!props.vehicle.model && !props.hideShipPage,
);

const editVisible = computed(() => props.editable && !props.hideEdit);

const visibleGroups = computed(() =>
  [
    { name: "database", visible: shipPageVisible.value },
    { name: "edit", visible: editVisible.value || loadoutVisible.value },
    {
      name: "manage",
      visible: loadoutsVisible.value || cargoVisible.value || logVisible.value,
    },
    { name: "organize", visible: props.editable && !props.onVehiclePage },
    { name: "remove", visible: props.editable },
  ].filter((group) => group.visible),
);

const separatorBefore = (name: string) =>
  visibleGroups.value.findIndex((group) => group.name === name) > 0;
</script>

<template>
  <BtnDropdown
    :size="size"
    :variant="variant"
    class="panel-edit-menu"
    data-test="vehicle-menu"
    expand-left
    expand-bottom
  >
    <Btn
      v-if="shipPageVisible"
      data-test="vehicle-ship-page"
      :to="{
        name: 'ship',
        params: {
          slug: vehicle.model.slug,
        },
      }"
    >
      <DuotoneGlyph :glyph="SHIP_GLYPH" />
      <span>{{ t("actions.vehicleOverview.shipDatabase") }}</span>
    </Btn>
    <hr v-if="separatorBefore('edit')" />
    <Btn
      v-if="editVisible"
      :aria-label="t('actions.edit')"
      data-test="vehicle-edit"
      @click="openEdit"
    >
      <i class="fa fa-pencil" />
      <span>{{ t("actions.edit") }}</span>
    </Btn>
    <Btn
      v-if="loadoutVisible"
      :aria-label="
        loadoutEditable
          ? t('actions.hangar.editLoadout')
          : t('labels.model.addons')
      "
      data-test="vehicle-loadout"
      @click="openLoadout"
    >
      <i class="fa-duotone fa-puzzle" />
      <span>
        {{
          loadoutEditable
            ? t("actions.hangar.editLoadout")
            : t("labels.model.addons")
        }}
      </span>
    </Btn>
    <hr v-if="separatorBefore('manage')" />
    <Btn
      v-if="loadoutsVisible"
      :aria-label="t('actions.hangar.manageLoadouts')"
      data-test="vehicle-manage-loadouts"
      :to="loadoutsRoute"
    >
      <i class="fa-duotone fa-crosshairs" />
      <span>{{ t("actions.hangar.manageLoadouts") }}</span>
    </Btn>
    <Btn
      v-if="cargoVisible"
      :aria-label="t('actions.hangar.manageCargo')"
      data-test="vehicle-manage-cargo"
      :to="cargoRoute"
    >
      <i class="fa-duotone fa-boxes-stacked" />
      <span>{{ t("actions.hangar.manageCargo") }}</span>
    </Btn>
    <Btn
      v-if="logVisible"
      :aria-label="t('actions.vehicleLog.open')"
      data-test="vehicle-log"
      :to="logRoute"
    >
      <i class="fa-duotone fa-book" />
      <span>{{ t("actions.vehicleLog.open") }}</span>
    </Btn>
    <hr v-if="separatorBefore('organize')" />
    <Btn
      v-if="hideable"
      :aria-label="
        vehicle.hiddenByUser
          ? t('actions.hangar.showInHangar')
          : t('actions.hangar.hideFromHangar')
      "
      :disabled="updating"
      data-test="vehicle-toggle-hidden"
      @click="toggleHidden"
    >
      <i
        class="fa-duotone"
        :class="vehicle.hiddenByUser ? 'fa-garage' : 'fa-ghost'"
      />
      <span>
        {{
          vehicle.hiddenByUser
            ? t("actions.hangar.showInHangar")
            : t("actions.hangar.hideFromHangar")
        }}
      </span>
    </Btn>
    <Btn
      v-if="editable && !onVehiclePage && !wishlist"
      :aria-label="t('actions.addToWishlist')"
      :disabled="updating"
      data-test="vehicle-add-to-wishlist"
      @click="addToWishlist"
    >
      <i class="fa-duotone fa-wand-sparkles" />
      <span>{{ t("actions.addToWishlist") }}</span>
    </Btn>
    <Btn
      v-if="editable && !onVehiclePage && wishlist"
      :aria-label="t('actions.addToHangar')"
      :disabled="updating"
      data-test="vehicle-add-to-hangar"
      @click="addToHangar"
    >
      <i class="fa-duotone fa-garage" />
      <span>{{ t("actions.addToHangar") }}</span>
    </Btn>
    <hr v-if="separatorBefore('remove')" />
    <Btn
      :tone="BtnTonesEnum.DANGER"
      v-if="editable"
      :aria-label="t('actions.remove')"
      :disabled="deleting"
      data-test="vehicle-remove"
      @click="remove"
    >
      <i class="fa-light fa-trash" />
      <span>{{ t("actions.remove") }}</span>
    </Btn>
  </BtnDropdown>
</template>
