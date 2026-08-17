<script lang="ts">
export default {
  name: "VehicleContextMenu",
};
</script>

<script lang="ts" setup>
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

type Props = {
  vehicle: Vehicle;
  editable?: boolean;
  hideEdit?: boolean;
  wishlist?: boolean;
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  hideEdit: false,
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
    (props.editable || hasAddons) &&
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

const loadoutsRoute = computed(() => ({
  name: "hangar-vehicle-loadouts",
  params: { id: props.vehicle.serial || props.vehicle.id },
}));

const cargoRoute = computed(() => ({
  name: "hangar-vehicle-cargo",
  params: { id: props.vehicle.serial || props.vehicle.id },
}));

const cargoVisible = computed(
  () =>
    props.editable &&
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
      v-if="editable && !hideEdit"
      :aria-label="t('actions.edit')"
      data-test="vehicle-edit"
      @click="openEditModal"
    >
      <i class="fa fa-pencil" />
      <span>{{ t("actions.edit") }}</span>
    </Btn>
    <Btn
      v-if="vehicle.model"
      :to="{
        name: 'ship',
        params: {
          slug: vehicle.model.slug,
        },
      }"
    >
      <i class="fa-duotone fa-starship" />
      <span>{{ t("actions.showDetailPage") }}</span>
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
      v-if="editable"
      :aria-label="t('actions.hangar.editName')"
      data-test="vehicle-edit-name"
      @click="openNamingModal"
    >
      <i class="fa fa-signature" />
      <span>{{ t("actions.hangar.editName") }}</span>
    </Btn>
    <Btn
      v-if="editable && !wishlist"
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
      @click="openAddonsModal"
    >
      <i class="fa fa-plus-octagon" />
      <span>{{ t("labels.model.addons") }}</span>
    </Btn>
    <Btn
      v-if="editable && vehicle.model?.inGame"
      :aria-label="t('actions.hangar.manageLoadouts')"
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
