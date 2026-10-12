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
import { FeatureFlagName, type Vehicle } from "@/services/fyApi";
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

type Props = {
  vehicle: Vehicle;
  editable?: boolean;
  hideEdit?: boolean;
  onVehiclePage?: boolean;
  // Where the page edits the groups itself, as the overview's card does.
  hideGroups?: boolean;
  wishlist?: boolean;
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  hideEdit: false,
  onVehiclePage: false,
  hideGroups: false,
  wishlist: false,
  variant: undefined,
  size: undefined,
  inGroup: false,
});

const { t } = useI18n();

const { isFeatureEnabled } = useFeatures();

const deleting = ref(false);

const updating = ref(false);

const hasAddons = computed(() => {
  if (!props.vehicle) {
    return false;
  }

  return (
    props.vehicle.modelModuleIds.length || props.vehicle.modelUpgradeIds.length
  );
});

const upgradable = computed(() => {
  if (!props.vehicle) {
    return false;
  }

  return (
    (props.editable || hasAddons.value) &&
    (props.vehicle.model.hasModules || props.vehicle.model.hasUpgrades)
  );
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

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/Vehicles/Modal/index.vue"),
    props: {
      vehicle: props.vehicle,
      wishlist: props.wishlist,
    },
  });
};

const openNamingModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/NamingModal/index.vue"),
    props: {
      vehicle: props.vehicle,
    },
  });
};

const openEditGroupsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/GroupsModal/index.vue"),
    props: {
      vehicle: props.vehicle,
    },
  });
};

const openAddonsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/AddonsModal/index.vue"),
    props: {
      vehicle: props.vehicle,
      editable: props.editable,
    },
  });
};

const openImageModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/ImageModal/index.vue"),
    props: {
      vehicle: props.vehicle,
    },
  });
};

const vehicleOverviewVisible = computed(
  () => props.editable && isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW),
);

// The vehicle page carries these as tabs and header buttons already.
const pageShortcutsVisible = computed(
  () => vehicleOverviewVisible.value && !props.onVehiclePage,
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
      v-if="pageShortcutsVisible"
      :aria-label="t('actions.vehicleLog.open')"
      data-test="vehicle-log"
      :to="logRoute"
    >
      <i class="fa-duotone fa-book" />
      <span>{{ t("actions.vehicleLog.open") }}</span>
    </Btn>
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
      v-if="vehicle.model"
      data-test="vehicle-ship-page"
      :to="{
        name: 'ship',
        params: {
          slug: vehicle.model.slug,
        },
      }"
    >
      <DuotoneGlyph :glyph="SHIP_GLYPH" />
      <span>{{ t("actions.showDetailPage") }}</span>
    </Btn>
    <Btn
      v-if="editable && !hideEdit && !onVehiclePage"
      :aria-label="t('actions.edit')"
      data-test="vehicle-edit"
      @click="openEditModal"
    >
      <i class="fa fa-pencil" />
      <span>{{ t("actions.edit") }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="t('actions.hangar.editName')"
      data-test="vehicle-edit-name"
      @click="openNamingModal"
    >
      <i class="fa fa-signature" />
      <span>{{ t("actions.hangar.editName") }}</span>
    </Btn>
    <Btn
      v-if="pageShortcutsVisible"
      :aria-label="
        vehicle.image
          ? t('actions.vehicleOverview.changePicture')
          : t('actions.vehicleOverview.uploadPicture')
      "
      data-test="vehicle-change-picture"
      @click="openImageModal"
    >
      <i class="fa-duotone fa-camera" />
      <span>
        {{
          vehicle.image
            ? t("actions.vehicleOverview.changePicture")
            : t("actions.vehicleOverview.uploadPicture")
        }}
      </span>
    </Btn>
    <Btn
      v-if="editable && !wishlist && !hideGroups"
      :aria-label="t('actions.hangar.editGroups')"
      data-test="vehicle-edit-groups"
      @click="openEditGroupsModal"
    >
      <i class="fa-duotone fa-object-group" />
      <span>{{ t("actions.hangar.editGroups") }}</span>
    </Btn>
    <Btn
      v-if="upgradable"
      :aria-label="t('labels.model.addons')"
      data-test="vehicle-addons"
      @click="openAddonsModal"
    >
      <i class="fa fa-plus-octagon" />
      <span>{{ t("labels.model.addons") }}</span>
    </Btn>
    <Btn
      v-if="editable && !wishlist"
      :aria-label="t('actions.addToWishlist')"
      :disabled="updating"
      data-test="vehicle-add-to-wishlist"
      @click="addToWishlist"
    >
      <i class="fa-duotone fa-wand-sparkles" />
      <span>{{ t("actions.addToWishlist") }}</span>
    </Btn>
    <Btn
      v-if="editable && wishlist"
      :aria-label="t('actions.addToHangar')"
      :disabled="updating"
      data-test="vehicle-add-to-hangar"
      @click="addToHangar"
    >
      <i class="fa-duotone fa-garage" />
      <span>{{ t("actions.addToHangar") }}</span>
    </Btn>
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
