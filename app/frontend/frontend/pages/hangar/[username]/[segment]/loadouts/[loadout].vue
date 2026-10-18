<script lang="ts">
export default {
  name: "HangarVehicleLoadoutPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Hardpoints from "@/frontend/components/Models/Hardpoints/index.vue";
import { VehicleLoadoutTabsEnum } from "@/frontend/components/Vehicles/LoadoutModal/types";
import { useLoadoutFitting } from "@/frontend/composables/useLoadoutFitting";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useLoadoutEditor } from "@/frontend/composables/useLoadoutEditor";
import { useSessionStore } from "@/frontend/stores/session";
import {
  vehicleIdentifierFromSegment,
  vehicleRoute,
} from "@/frontend/utils/vehicleSegment";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import {
  type Vehicle,
  usePublicHangarVehicle,
  usePublicVehicleLoadout,
  usePublicVehicleLoadoutSlots,
  useModel,
  useShowVehicle,
  useVehicleLoadoutSlots,
  useVehicleLoadouts,
} from "@/services/fyApi";

const { t } = useI18n();

const route = useRoute();

const username = computed(() => String(route.params.username));

const identifier = computed(() => {
  const segment = String(route.params.segment ?? "");

  return vehicleIdentifierFromSegment(segment) ?? segment;
});

const loadoutId = computed(() => String(route.params.loadout));

// The owner reads their own ship; anyone else reads what its public hangar
// shows, a private one opened by its share link.
const sessionStore = useSessionStore();

const isOwner = computed(
  () =>
    sessionStore.currentUser?.username?.toLowerCase() ===
    username.value.toLowerCase(),
);

const publicParams = computed(() =>
  route.query.share ? { share: String(route.query.share) } : {},
);

const { data: ownVehicle, ...ownVehicleStatus } = useShowVehicle(identifier, {
  query: { enabled: isOwner },
});

const ownVehicleId = computed(() => ownVehicle.value?.id ?? "");

const { data: ownLoadouts, ...ownLoadoutsStatus } = useVehicleLoadouts(
  ownVehicleId,
  { query: { enabled: () => isOwner.value && !!ownVehicle.value } },
);

const { data: ownSlots } = useVehicleLoadoutSlots(ownVehicleId, loadoutId, {
  query: { enabled: () => isOwner.value && !!ownVehicle.value },
});

const { data: publicVehicle, ...publicVehicleStatus } = usePublicHangarVehicle(
  username,
  identifier,
  publicParams,
  { query: { enabled: () => !isOwner.value } },
);

const { data: publicLoadout, ...publicLoadoutStatus } = usePublicVehicleLoadout(
  username,
  identifier,
  loadoutId,
  publicParams,
  {
    query: { enabled: () => !isOwner.value },
  },
);

const { data: publicSlots } = usePublicVehicleLoadoutSlots(
  username,
  identifier,
  loadoutId,
  publicParams,
  { query: { enabled: () => !isOwner.value } },
);

const vehicle = computed(() =>
  isOwner.value ? ownVehicle.value : publicVehicle.value,
);

const loadout = computed(() =>
  isOwner.value
    ? ownLoadouts.value?.find((entry) => entry.id === loadoutId.value)
    : publicLoadout.value,
);

const vehicleStatus = computed(() =>
  isOwner.value ? ownVehicleStatus : publicVehicleStatus,
);

const loadoutStatus = computed(() =>
  isOwner.value ? ownLoadoutsStatus : publicLoadoutStatus,
);

// The full model, as the ship page has it, for the hardpoints' figures.
const { data: model } = useModel(() => vehicle.value?.model.slug ?? "", {
  query: { enabled: () => !!vehicle.value },
});

const { hardpoints } = useLoadoutFitting({
  modelSlug: () => vehicle.value?.model.slug,
  loadoutSlots: () => (isOwner.value ? ownSlots.value : publicSlots.value),
  items: () => loadout.value?.items,
});

const vehicleName = computed(
  () => vehicle.value?.name || vehicle.value?.model.name || "",
);

const { updateMetaInfo } = useMetaInfo();

watch(
  [loadout, vehicleName],
  () => {
    if (!loadout.value) return;

    updateMetaInfo({
      title: [loadout.value.name, vehicleName.value]
        .filter(Boolean)
        .join(" · "),
    });
  },
  { immediate: true },
);

const crumbs = computed<Crumb[]>(() => {
  if (!vehicle.value) return [];

  if (!isOwner.value) {
    return [
      {
        to: { name: "hangar-public", params: { username: username.value } },
        label: username.value,
      },
    ];
  }

  return [
    { to: { name: "hangar" }, label: t("nav.hangar.index") },
    {
      to: vehicleRoute(
        "hangar-vehicle-loadouts",
        vehicle.value as Vehicle,
        username.value,
      ),
      label: vehicleName.value,
    },
  ];
});

const { loadoutEditorAvailable } = useLoadoutEditor();

const { openLoadoutModal } = useVehicleModals();

const editable = computed(
  () =>
    isOwner.value &&
    !!ownVehicle.value &&
    loadoutEditorAvailable(ownVehicle.value),
);

const edit = () => {
  if (!ownVehicle.value) return;

  openLoadoutModal(ownVehicle.value, {
    editable: true,
    loadoutId: loadoutId.value,
    tab: VehicleLoadoutTabsEnum.MODULES,
  });
};
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <AsyncData :async-status="vehicleStatus">
    <template #resolved>
      <AsyncData :async-status="loadoutStatus">
        <template #resolved>
          <template v-if="vehicle && loadout">
            <Heading size="hero" hero inline-sub-heading>
              <template #default>
                {{ loadout.name }}
              </template>
              <template #subHeading>
                {{ vehicleName }}
              </template>
            </Heading>

            <Teleport v-if="editable" to="#header-right">
              <Btn
                :size="BtnSizesEnum.MD"
                mobile-icon-only
                data-test="vehicle-loadout-page-edit"
                @click="edit"
              >
                <i class="fa-duotone fa-screwdriver-wrench" />
                {{ t("actions.vehicleLoadout.editLoadout") }}
              </Btn>
            </Teleport>

            <Hardpoints
              v-if="model && hardpoints"
              :model="model"
              :fitting="hardpoints"
            />
          </template>
        </template>
      </AsyncData>
    </template>
  </AsyncData>
</template>
