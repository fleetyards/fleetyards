<script lang="ts">
export default {
  name: "ModelLoadoutHolo",
};
</script>

<script lang="ts" setup>
import {
  FeatureFlagName,
  type LoadoutComponentRef,
  type LoadoutSlot,
  useModelLoadoutPreview,
  useModelLoadoutSlots,
} from "@/services/fyApi";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  componentTabOf,
  filedCategory,
} from "@/frontend/composables/useComponentFitting";
import {
  builtInHighlights,
  builtInKind,
  categoryColor,
  loadoutCargoGrids,
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
import { BOX_COLOR } from "@/shared/components/HoloViewer/boxes";
import { BUILT_IN_COLOR } from "@/shared/components/HoloViewer/builtIns";
import { DOOR_COLOR } from "@/shared/components/HoloViewer/doors";
import { CARGO_GRID_COLOR } from "@/shared/components/HoloViewer/cargo";
import { humanizeHoldName } from "@/shared/utils/CargoHolds";
import { useI18n } from "@/shared/composables/useI18n";
import {
  servicingAreaLabel,
  servicingAreaSize,
} from "@/shared/utils/LandingServices";

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

const { t, toNumber } = useI18n();

const viewer = ref<InstanceType<typeof HoloViewer>>();

const enableFullscreen = () => viewer.value?.enableFullscreen();

defineExpose({ enableFullscreen });

const { data: preview } = useModelLoadoutPreview(() => props.modelSlug);

const { data: stockSlots } = useModelLoadoutSlots(() => props.modelSlug, {
  query: { enabled: () => !props.slots },
});

const loadoutSlots = computed(() => props.slots ?? stockSlots.value ?? []);

type PointedPart = {
  slot: LoadoutSlot;
  category?: string;
};

// Every slot by the path its part on the holo is named by.
const partsByPath = computed(() => {
  const parts = new Map<string, PointedPart>();

  const walk = (slots: LoadoutSlot[], prefix: string) => {
    for (const slot of slots) {
      const path = `${prefix}${slot.name}`;
      parts.set(path, { slot, category: filedCategory(slot) });
      walk(slot.slots, `${path}/`);
    }
  };

  walk(loadoutSlots.value, "");

  return parts;
});

const pointedPath = ref<string>();
const pointedArea = ref<string>();
const pointedBuiltIn = ref<string>();
const pointedDoor = ref<string>();
const pointedCargoGrid = ref<string>();

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

const doors = computed(() =>
  doorAnimationEnabled.value || doorHighlightEnabled.value
    ? (preview.value?.doors ?? [])
    : [],
);

const { isOpen, openDoors, toggleDoor } = useHoloDoors(doors, doorsOpen);

const router = useRouter();

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
    builtIns: builtInHighlights(preview.value.ports),
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

// Where the pointer is over the holo, for the card to follow it.
const cursor = ref({ x: 0, y: 0, flipX: false, flipY: false });

const trackPointer = (event: PointerEvent) => {
  const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
  const x = event.clientX - rect.left;
  const y = event.clientY - rect.top;

  cursor.value = {
    x,
    y,
    flipX: x > rect.width - 260,
    flipY: y > rect.height - 120,
  };
};

const pointedPart = computed(() =>
  pointedPath.value ? partsByPath.value.get(pointedPath.value) : undefined,
);

type BuiltInPart = Pick<LoadoutComponentRef, "name" | "slug" | "size">;

// A built-in item by its port: the part its slot holds. A nested port is found
// through its parents, as the slots are pathed.
const builtInPart = (id: string) => {
  const ports = preview.value?.ports ?? [];
  const port = ports.find((candidate) => candidate.name === id);

  const names: string[] = [];
  for (
    let current = port;
    current;
    current = current.parent
      ? ports.find((candidate) => candidate.name === current?.parent)
      : undefined
  ) {
    names.unshift(current.name.toLowerCase());
    if (names.length > ports.length) break;
  }

  const path = names.join("/");
  const slot = [...partsByPath.value].find(
    ([candidate]) => candidate.toLowerCase() === path,
  )?.[1].slot;

  const part: BuiltInPart | undefined = slot?.fitted ?? slot?.stock;
  if (part || !port?.defaultItemName) return { port, part };

  // Kept in the hull with no slot of its own, a stowed mining bag: named from
  // the catalogue.
  return {
    port,
    part: {
      name: port.defaultItemName,
      slug: port.defaultItemSlug ?? undefined,
    },
  };
};

const openBuiltIn = (id: string) => {
  const { part } = builtInPart(id);
  if (!part?.slug) return;

  void router.push({ name: "component", params: { slug: part.slug } });
};

const DOOR_KINDS: Record<string, string> = {
  door: "door",
  airlock: "airlock",
  elevator: "elevator",
  hatch: "hatch",
  side_door: "sideDoor",
  ramp: "ramp",
};

const card = computed(() => {
  if (pointedPart.value) {
    const { slot, category } = pointedPart.value;
    const part = slot.emptied ? undefined : (slot.fitted ?? slot.stock);
    const tab = componentTabOf(category);

    if (!part) return undefined;

    return {
      kicker: tab ? t(`labels.vehicleLoadout.tabs.${tab.id}`) : undefined,
      color: categoryColor(category),
      title: part.name,
      details: [
        part.size ? `S${part.size}` : undefined,
        part.itemClassLabel,
        part.gradeLabel
          ? `${t("labels.component.grade")} ${part.gradeLabel}`
          : undefined,
      ].filter(Boolean),
    };
  }

  if (pointedBuiltIn.value) {
    const { port, part } = builtInPart(pointedBuiltIn.value);
    const kind = (port && builtInKind(port)) ?? "weapon";

    return {
      kicker: t(`labels.loadoutHoloBuiltInKinds.${kind}`),
      color: BUILT_IN_COLOR,
      title: part?.name ?? port?.defaultItem ?? pointedBuiltIn.value,
      details: [
        part?.size ? `S${part.size}` : undefined,
        t("labels.loadoutHoloBuiltIn"),
        part?.slug ? t("actions.holoViewer.builtIn") : undefined,
      ].filter(Boolean),
    };
  }

  const door = doorHighlightEnabled.value
    ? doors.value.find((candidate) => candidate.id === pointedDoor.value)
    : undefined;

  if (door) {
    const kind = DOOR_KINDS[door.kind ?? ""] ?? "door";

    return {
      kicker: t("labels.loadoutHoloDoor"),
      color: DOOR_COLOR,
      title: t(`labels.loadoutHoloDoorKinds.${kind}`),
      details: doorAnimationEnabled.value
        ? [
            isOpen(door.id)
              ? t("actions.holoViewer.door.close")
              : t("actions.holoViewer.door.open"),
          ]
        : [],
    };
  }

  const grid = cargoGridsEnabled.value
    ? preview.value?.cargoGrids.find(
        (candidate) => candidate.name === pointedCargoGrid.value,
      )
    : undefined;

  if (grid) {
    const [width, height, length] = grid.size;

    return {
      kicker: t("labels.loadoutHoloCargoGrid"),
      color: CARGO_GRID_COLOR,
      title: humanizeHoldName(grid.name),
      details: [
        grid.scu ? `${toNumber(grid.scu)} SCU` : undefined,
        `${toNumber(length)} × ${toNumber(width)} × ${toNumber(height)} m`,
      ].filter(Boolean),
    };
  }

  const area = preview.value?.servicingAreas.find(
    (candidate) => candidate.key === pointedArea.value,
  );

  if (!area) return undefined;

  return {
    kicker: t("labels.loadoutHoloServicingArea"),
    color: BOX_COLOR,
    title: servicingAreaLabel(area, area.index, { t }),
    details: [servicingAreaSize(area, { toNumber })],
  };
});

watch(holoModel, (model) => {
  if (!model) {
    pointedPath.value = undefined;
    pointedArea.value = undefined;
    pointedBuiltIn.value = undefined;
    pointedDoor.value = undefined;
    pointedCargoGrid.value = undefined;
  }
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
      </Btn>
    </template>
    <div
      v-if="card"
      class="model-loadout-holo__card"
      :class="{
        'model-loadout-holo__card--flip-x': cursor.flipX,
        'model-loadout-holo__card--flip-y': cursor.flipY,
      }"
      :style="{
        '--card-x': `${cursor.x}px`,
        '--card-y': `${cursor.y}px`,
        '--card-color': card.color,
      }"
      role="tooltip"
      :data-test="`${testId}-card`"
    >
      <span v-if="card.kicker" class="model-loadout-holo__kicker">
        {{ card.kicker }}
      </span>
      <strong class="model-loadout-holo__title">{{ card.title }}</strong>
      <span v-if="card.details.length" class="model-loadout-holo__details">
        {{ card.details.join(" · ") }}
      </span>
    </div>
  </HoloViewer>
</template>

<style lang="scss" scoped>
.model-loadout-holo__card {
  --card-offset: 16px;

  position: absolute;
  top: var(--card-y);
  left: var(--card-x);
  z-index: 3;
  display: flex;
  flex-direction: column;
  gap: 2px;
  max-width: 240px;
  padding: 8px 12px;
  border: 1px solid var(--card-color, var(--color-edge));
  border-radius: 6px;
  background: rgb(10 14 20 / 88%);
  color: var(--color-text);
  font-size: 0.75rem;
  pointer-events: none;
  transform: translate(var(--card-offset), var(--card-offset));

  &--flip-x {
    transform: translate(calc(-100% - var(--card-offset)), var(--card-offset));
  }

  &--flip-y {
    transform: translate(var(--card-offset), calc(-100% - var(--card-offset)));
  }

  &--flip-x#{&}--flip-y {
    transform: translate(
      calc(-100% - var(--card-offset)),
      calc(-100% - var(--card-offset))
    );
  }
}

.model-loadout-holo__kicker {
  color: var(--card-color, var(--color-text-dim));
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 0.625rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.model-loadout-holo__title {
  color: var(--color-lifted);
  font-weight: 600;
}

.model-loadout-holo__details {
  color: var(--color-text-dim);
  font-variant-numeric: tabular-nums;
}
</style>
