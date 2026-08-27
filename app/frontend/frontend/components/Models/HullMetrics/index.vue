<script lang="ts">
export default {
  name: "ModelHullMetrics",
};
</script>

<script lang="ts" setup>
import CompositionBar from "@/frontend/components/Models/CompositionBar/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { ModelHullPart, ModelHullDoor } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useHullParts } from "@/frontend/composables/useHullParts";

type Props = {
  hullHealth?: number;
  hullParts?: ModelHullPart[];
  hullDoors?: ModelHullDoor[];
};

const props = withDefaults(defineProps<Props>(), {
  hullHealth: undefined,
  hullParts: () => [],
  hullDoors: () => [],
});

const { t, toNumber } = useI18n();

const comlink = useComlink();

const { composition } = useHullParts(() => props.hullParts);

const round = (value: number) => Math.round(value);
// `toNumber` renders any falsy value as "N/A", which is wrong for a genuine
// zero — nothing absorbed is a real result, not missing data.
const num = (value: number) => (value ? toNumber(value, "integer") : "0");

const hoveredCategory = ref<string | null>(null);

const hullHp = computed(() => props.hullHealth ?? 0);
const hasData = computed(
  () =>
    hullHp.value > 0 ||
    props.hullParts.length > 0 ||
    props.hullDoors.length > 0,
);

// Doors are their own area, deliberately outside hull HP — shooting one does not
// damage the hull.
const doorHp = computed(() =>
  props.hullDoors.reduce((sum, door) => sum + door.health, 0),
);

const openPartsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Models/HullPartsModal/index.vue"),
    wide: true,
    props: {
      hullHealth: props.hullHealth,
      hullParts: props.hullParts,
      hullDoors: props.hullDoors,
    },
  });
};
</script>

<template>
  <MetricsCard
    v-if="hasData"
    :title="t('labels.hull.title')"
    class="hull-panel"
  >
    <div class="metrics-card__hero">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">
          {{ t("labels.hull.hullHp") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ num(round(hullHp)) }}
          <span class="metrics-card__tile__unit">HP</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.hull.hullHpSub") }}
        </div>
      </div>
      <div v-if="hullParts.length" class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.hull.parts") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ num(hullParts.length) }}
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.hull.partsSub", { count: composition.length }) }}
        </div>
      </div>
      <div v-if="hullDoors.length" class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.hull.doors") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ num(round(doorHp)) }}
          <span class="metrics-card__tile__unit">HP</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.hull.doorsSub", { count: hullDoors.length }) }}
        </div>
      </div>
    </div>

    <template v-if="composition.length">
      <div class="metrics-card__section-label">
        {{ t("labels.hull.composition") }}
      </div>
      <CompositionBar
        :segments="composition"
        :highlighted="hoveredCategory"
        @highlight="hoveredCategory = $event"
      />
    </template>

    <div v-if="hullParts.length" class="metrics-card__actions">
      <button
        type="button"
        class="metrics-card__toggle"
        @click="openPartsModal"
      >
        {{ t("labels.hull.showParts") }}
      </button>
    </div>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">
        {{ t("labels.hull.hint") }}
      </span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";
</style>
