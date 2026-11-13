<script lang="ts">
export default {
  name: "ModelLoadoutHolo",
};
</script>

<script lang="ts" setup>
import {
  type LoadoutSlot,
  useModelLoadoutPreview,
  useModelLoadoutSlots,
} from "@/services/fyApi";
import {
  componentTabOf,
  filedCategory,
} from "@/frontend/composables/useComponentFitting";
import {
  categoryColor,
  loadoutMounts,
  type PreviewSlot,
} from "@/frontend/utils/loadoutPreview";
import { BOX_COLOR } from "@/shared/components/HoloViewer/boxes";
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

const previewSlots = (slots: LoadoutSlot[], prefix = ""): PreviewSlot[] =>
  slots.map((slot) => {
    const path = `${prefix}${slot.name}`;

    return {
      name: slot.name,
      path,
      part: slot.emptied ? null : (slot.fitted ?? slot.stock ?? null),
      active: path === pointedPath.value,
      refitted: !!slot.fitted && slot.fitted.id !== slot.stock?.id,
      category: filedCategory(slot),
      slots: previewSlots(slot.slots, `${path}/`),
    };
  });

const holoModel = computed(() => {
  const hull = preview.value?.holoHull;

  if (!preview.value || !hull?.url) return undefined;

  return {
    path: hull.url,
    size: hull.size ?? undefined,
    mounts: loadoutMounts(preview.value, previewSlots(loadoutSlots.value)),
    boxes: preview.value.servicingAreas.map((area) => ({
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
  }
});
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
    @unavailable="emit('unavailable')"
  >
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
