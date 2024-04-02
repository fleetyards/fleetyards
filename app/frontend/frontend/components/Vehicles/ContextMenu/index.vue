<template>
  <BtnDropdown
    :size="size"
    :variant="variant"
    class="panel-edit-menu"
    data-test="vehicle-menu"
    expand-left
    inline
  >
    <Btn
      v-if="editable && !hideEdit"
      :aria-label="t('actions.edit')"
      :size="BtnSizesEnum.SMALL"
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
      :size="BtnSizesEnum.SMALL"
    >
      <i class="fad fa-starship" />
      <span>{{ t("actions.showDetailPage") }}</span>
    </Btn>
    <Btn
      v-if="editable && !wishlist"
      :aria-label="t('actions.addToWishlist')"
      :size="BtnSizesEnum.SMALL"
      :disabled="updating"
      data-test="vehicle-add-to-wishlist"
      @click="addToWishlist"
    >
      <i class="fad fa-wand-sparkles" />
      <span>{{ t("actions.addToWishlist") }}</span>
    </Btn>
    <Btn
      v-if="editable && wishlist"
      :aria-label="t('actions.addToHangar')"
      :size="BtnSizesEnum.SMALL"
      :disabled="updating"
      data-test="vehicle-add-to-hangar"
      @click="addToHangar"
    >
      <i class="fad fa-garage" />
      <span>{{ t("actions.addToHangar") }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="t('actions.hangar.editName')"
      :size="BtnSizesEnum.SMALL"
      data-test="vehicle-edit-name"
      @click="openNamingModal"
    >
      <i class="fa fa-signature" />
      <span>{{ t("actions.hangar.editName") }}</span>
    </Btn>
    <Btn
      v-if="editable && !wishlist"
      :aria-label="t('actions.hangar.editGroups')"
      :size="BtnSizesEnum.SMALL"
      data-test="vehicle-edit-groups"
      @click="openEditGroupsModal"
    >
      <i class="fad fa-object-group" />
      <span>{{ t("actions.hangar.editGroups") }}</span>
    </Btn>
    <Btn
      v-if="upgradable"
      :aria-label="t('labels.model.addons')"
      :size="BtnSizesEnum.SMALL"
      @click="openAddonsModal"
    >
      <i class="fa fa-plus-octagon" />
      <span>{{ t("labels.model.addons") }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="t('actions.remove')"
      :size="BtnSizesEnum.SMALL"
      :disabled="deleting"
      data-test="vehicle-remove"
      @click="remove"
    >
      <i class="fal fa-trash" />
      <span>{{ t("actions.remove") }}</span>
    </Btn>
  </BtnDropdown>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import type { Vehicle } from "@/services/fyApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useApiClient } from "@/frontend/composables/useApiClient";

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
  variant: BtnVariantsEnum.LINK,
  size: BtnSizesEnum.SMALL,
  inGroup: false,
});

const { t } = useI18n();

const { displayConfirm } = useNoty();

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

const { vehicles: vehiclesService } = useApiClient();

const addToWishlist = async () => {
  if (!props.vehicle) {
    return;
  }

  updating.value = true;

  try {
    await vehiclesService.vehicleUpdate({
      id: props.vehicle.id,
      requestBody: {
        wanted: true,
      },
    });
  } catch (error) {
    console.error(error);
  }

  updating.value = false;
};

const addToHangar = async () => {
  if (!props.vehicle) {
    return;
  }

  updating.value = true;

  try {
    await vehiclesService.vehicleUpdate({
      id: props.vehicle.id,
      requestBody: {
        wanted: false,
      },
    });
  } catch (error) {
    console.error(error);
  }

  updating.value = false;
};

const remove = () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.vehicle.destroy"),
    onConfirm: () => {
      destroy();
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};

const destroy = async () => {
  if (!props.vehicle) {
    return;
  }

  try {
    await vehiclesService.vehicleDestroy({
      id: props.vehicle.id,
    });
  } catch (error) {
    console.error(error);
  }

  deleting.value = false;
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
</script>

<script lang="ts">
export default {
  name: "VehicleContextMenu",
};
</script>
