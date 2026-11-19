<script lang="ts">
export default {
  name: "ModelLoadoutHolo",
};
</script>

<script lang="ts" setup>
import {
  FeatureFlagName,
  type LoadoutSlot,
  useModelLoadoutPreview,
  useModelLoadoutSlots,
} from "@/services/fyApi";
import Btn from "@/shared/components/base/Btn/index.vue";
import BetaBadge from "@/shared/components/BetaBadge/index.vue";
import { filedCategory } from "@/frontend/composables/useComponentFitting";
import {
  builtInHighlights,
  loadoutCargoGrids,
  loadoutHull,
  loadoutMounts,
  type PreviewSlot,
} from "@/frontend/utils/loadoutPreview";
import { useHoloDoors } from "@/frontend/composables/useHoloDoors";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  LOADOUT_HOLO_LAYERS,
  type LoadoutHoloLayers,
  useModelsStore,
} from "@/frontend/stores/models";
import { useLoadoutHoloCard } from "@/frontend/composables/useLoadoutHoloCard";
import LoadoutHoloCard from "@/frontend/components/Loadout/HoloCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  modelSlug: string;
  // A fitting to show; without one the ship's stock loadout is.
  slots?: LoadoutSlot[];
  testId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  slots: undefined,
  testId: "model-loadout-holo",
});

const emit = defineEmits<{
  unavailable: [];
}>();

const HoloViewer = defineAsyncComponent(
  () => import("@/shared/components/HoloViewer/index.vue"),
);

const { t } = useI18n();

const viewer = ref<InstanceType<typeof HoloViewer>>();

const enableFullscreen = () => viewer.value?.enableFullscreen();

defineExpose({ enableFullscreen });

const { data: preview } = useModelLoadoutPreview(() => props.modelSlug);

const { data: stockSlots } = useModelLoadoutSlots(() => props.modelSlug, {
  query: { enabled: () => !props.slots },
});

const loadoutSlots = computed(() => props.slots ?? stockSlots.value ?? []);

const pointedPath = ref<string>();

const modelsStore = useModelsStore();

const layer = (key: keyof LoadoutHoloLayers) =>
  computed({
    get: () => modelsStore.loadoutHoloLayers?.[key] ?? LOADOUT_HOLO_LAYERS[key],
    set: (shown: boolean) => {
      modelsStore.loadoutHoloLayers = {
        ...LOADOUT_HOLO_LAYERS,
        ...modelsStore.loadoutHoloLayers,
        [key]: shown,
      };
    },
  });

const servicingAreasShown = layer("servicingAreas");
const cargoGridsShown = layer("cargoGrids");
const doorsOpen = layer("doorsOpen");
const doorsMarked = layer("doorsMarked");

const { isFeatureEnabled } = useFeatures();

const servicingAreasEnabled = computed(() =>
  isFeatureEnabled(FeatureFlagName.HOLO_SERVICING_AREAS),
);
const cargoGridsEnabled = computed(() =>
  isFeatureEnabled(FeatureFlagName.HOLO_CARGO_GRIDS),
);
const doorAnimationEnabled = computed(() =>
  isFeatureEnabled(FeatureFlagName.HOLO_DOOR_ANIMATION),
);
const doorHighlightEnabled = computed(() =>
  isFeatureEnabled(FeatureFlagName.HOLO_DOOR_HIGHLIGHT),
);

const previewSlots = (slots: LoadoutSlot[], prefix = ""): PreviewSlot[] =>
  slots.map((slot) => {
    const path = `${prefix}${slot.name}`;

    return {
      name: slot.name,
      path,
      part: slot.emptied ? null : (slot.fitted ?? slot.stock ?? null),
      docked: !!slot.docked,
      active: path === pointedPath.value,
      refitted: !!slot.fitted && slot.fitted.id !== slot.stock?.id,
      category: filedCategory(slot),
      slots: previewSlots(slot.slots, `${path}/`),
    };
  });

// The hull as fitted: the ship's own ports, grids and doors, and those of the
// modules in its slots.
const fittedHull = computed(() =>
  preview.value
    ? loadoutHull(preview.value, previewSlots(loadoutSlots.value))
    : undefined,
);

const doors = computed(() =>
  doorAnimationEnabled.value || doorHighlightEnabled.value
    ? (fittedHull.value?.doors ?? [])
    : [],
);

const { isOpen, openDoors, toggleDoor } = useHoloDoors(doors, doorsOpen);

const router = useRouter();

const holoModel = computed(() => {
  const hull = preview.value?.holoHull;

  if (!preview.value || !hull?.url) return undefined;

  const slots = previewSlots(loadoutSlots.value);

  return {
    path: hull.url,
    size: hull.size ?? undefined,
    mounts: loadoutMounts(preview.value, slots),
    cargoGrids: cargoGridsEnabled.value
      ? loadoutCargoGrids(preview.value, slots)
      : [],
    doors: doors.value,
    openDoors: doorAnimationEnabled.value ? openDoors.value : [],
    doorTargets: doorHighlightEnabled.value || doorAnimationEnabled.value,
    doorHighlight: doorHighlightEnabled.value,
    doorsMarked: doorHighlightEnabled.value && doorsMarked.value,
    builtIns: builtInHighlights(fittedHull.value?.ports ?? []),
    layers: {
      boxes: servicingAreasShown.value,
      cargo: cargoGridsShown.value,
    },
    boxes: (servicingAreasEnabled.value
      ? preview.value.servicingAreas
      : []
    ).map((area) => ({
      id: area.key,
      position: area.position as [number, number, number],
      rotation: area.rotation as [number, number, number, number],
      size: area.size as [number, number, number],
      highlighted: area.key === pointedArea.value,
    })),
  };
});

const {
  pointedArea,
  pointedBuiltIn,
  pointedDoor,
  pointedCargoGrid,
  cursor,
  trackPointer,
  builtInPart,
  card,
  reset,
} = useLoadoutHoloCard({
  preview,
  slots: () => previewSlots(loadoutSlots.value),
  hull: fittedHull,
  doors,
  doorsAnimated: doorAnimationEnabled,
  doorsHighlighted: doorHighlightEnabled,
  isOpen,
  cargoGrids: cargoGridsEnabled,
  builtInHint: t("actions.holoViewer.builtIn"),
  pointedPath,
});

const openBuiltIn = (id: string) => {
  const { part } = builtInPart(id);
  if (!part?.slug) return;

  void router.push({ name: "component", params: { slug: part.slug } });
};

watch(holoModel, (model) => {
  if (!model) reset();
});

const servicingAreasLabel = computed(() =>
  servicingAreasShown.value
    ? t("actions.vehicleLoadout.hideServicingAreas")
    : t("actions.vehicleLoadout.showServicingAreas"),
);

const cargoGridsLabel = computed(() =>
  cargoGridsShown.value
    ? t("actions.holoViewer.cargo.disable")
    : t("actions.holoViewer.cargo.enable"),
);

const doorsMarkedLabel = computed(() =>
  doorsMarked.value
    ? t("actions.holoViewer.doorHighlight.disable")
    : t("actions.holoViewer.doorHighlight.enable"),
);

const doorsLabel = computed(() =>
  doorsOpen.value
    ? t("actions.holoViewer.doors.disable")
    : t("actions.holoViewer.doors.enable"),
);
</script>

<template>
  <HoloViewer
    v-if="holoModel"
    ref="viewer"
    :models="[holoModel]"
    :auto-rotate="false"
    hologram
    pickable
    :data-test="testId"
    @pointermove="trackPointer"
    @mount-point="pointedPath = $event"
    @box-point="pointedArea = $event"
    @built-in-point="pointedBuiltIn = $event"
    @built-in-select="openBuiltIn"
    @door-point="pointedDoor = $event"
    @cargo-point="pointedCargoGrid = $event"
    @door-select="doorAnimationEnabled && toggleDoor($event)"
    @unavailable="emit('unavailable')"
  >
    <template #actions>
      <Btn
        v-if="holoModel.boxes.length"
        v-tooltip="servicingAreasLabel"
        :aria-label="servicingAreasLabel"
        :aria-pressed="servicingAreasShown"
        :active="servicingAreasShown"
        :data-test="`${testId}-servicing-areas`"
        @click="servicingAreasShown = !servicingAreasShown"
      >
        <i class="fa-light fa-screwdriver-wrench" />
        <BetaBadge
          :feature="FeatureFlagName.HOLO_SERVICING_AREAS"
          in-control
          compact
        />
      </Btn>
      <Btn
        v-if="holoModel.cargoGrids.length"
        v-tooltip="cargoGridsLabel"
        :aria-label="cargoGridsLabel"
        :aria-pressed="cargoGridsShown"
        :active="cargoGridsShown"
        :data-test="`${testId}-cargo-grids`"
        @click="cargoGridsShown = !cargoGridsShown"
      >
        <i class="fa-light fa-boxes-stacked" />
        <BetaBadge
          :feature="FeatureFlagName.HOLO_CARGO_GRIDS"
          in-control
          compact
        />
      </Btn>
      <Btn
        v-if="doorHighlightEnabled && holoModel.doors.length"
        v-tooltip="doorsMarkedLabel"
        :aria-label="doorsMarkedLabel"
        :aria-pressed="doorsMarked"
        :active="doorsMarked"
        :data-test="`${testId}-door-highlight`"
        @click="doorsMarked = !doorsMarked"
      >
        <i class="fa-light fa-door-closed" />
        <BetaBadge
          :feature="FeatureFlagName.HOLO_DOOR_HIGHLIGHT"
          in-control
          compact
        />
      </Btn>
      <Btn
        v-if="doorAnimationEnabled && holoModel.doors.length"
        v-tooltip="doorsLabel"
        :aria-label="doorsLabel"
        :aria-pressed="doorsOpen"
        :active="doorsOpen"
        :data-test="`${testId}-doors`"
        @click="doorsOpen = !doorsOpen"
      >
        <i class="fa-light fa-arrows-left-right" />
        <BetaBadge
          :feature="FeatureFlagName.HOLO_DOOR_ANIMATION"
          in-control
          compact
        />
      </Btn>
    </template>
    <LoadoutHoloCard
      v-if="card"
      :card="card"
      :cursor="cursor"
      :test-id="`${testId}-card`"
    />
  </HoloViewer>
</template>
