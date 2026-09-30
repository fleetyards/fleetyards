<script lang="ts">
export default {
  name: "ModelCombatMetrics",
};
</script>

<script lang="ts" setup>
import { useTransition, TransitionPresets } from "@vueuse/core";
import type { Hardpoint } from "@/services/fyApi";
import CompositionBar from "@/frontend/components/Models/CompositionBar/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  CONTROL_GROUPS,
  useLoadoutStats,
  type ControlGroup,
  type DamageBreakdown,
} from "@/frontend/composables/useLoadoutStats";
import type { PortOverrides } from "@/frontend/composables/useLoadoutSim";
import { collectLoadoutWeapons } from "@/frontend/composables/usePenetrationCheck";

type Props = {
  hardpoints?: Hardpoint[];
  modelName?: string;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  hardpoints: () => [],
  modelName: "",
  loading: false,
});

const { t, toNumber } = useI18n();

const comlink = useComlink();

const weaponPoolSize = inject<Ref<number | undefined>>(
  "weaponPoolSize",
  ref(undefined),
);

// The Power Distribution control's pip choices; absent (standalone use) → auto.
const powerOverrides = inject<Ref<PortOverrides | undefined>>(
  "powerOverrides",
  ref(undefined),
);

const stats = useLoadoutStats(
  () => props.hardpoints,
  () => toValue(weaponPoolSize),
  () => toValue(powerOverrides),
);

const round = (value: number) => Math.round(value);

// toNumber renders 0 as "N/A"; here a zeroed value is a real 0 (e.g. weapons
// unpowered), so show "0" instead.
const dmg = (value: number) =>
  round(value) > 0 ? toNumber(round(value), "integer") : "0";

// Animate the power-reactive damage totals as the pip allocation changes.
const animate = { duration: 400, transition: TransitionPresets.easeOutCubic };
const animatedDps = useTransition(() => stats.value.dps.total, animate);
const animatedSustained = useTransition(
  () => stats.value.sustainedDps.total,
  animate,
);
const animatedAlpha = useTransition(() => stats.value.alpha.total, animate);

const hoveredType = ref<string | null>(null);

const damageTypes: {
  key: keyof DamageBreakdown;
  label: string;
  color: string;
}[] = [
  { key: "physical", label: "labels.combat.damagePhysical", color: "#c8c8c8" },
  { key: "energy", label: "labels.combat.damageEnergy", color: "#428bca" },
  {
    key: "distortion",
    label: "labels.combat.damageDistortion",
    color: "#38bec9",
  },
  { key: "thermal", label: "labels.combat.damageThermal", color: "#fa6800" },
];

const composition = computed(() =>
  damageTypes
    .map(({ key, label, color }) => ({
      key,
      label,
      color,
      value: stats.value.dps[key],
    }))
    .filter((entry) => entry.value > 0)
    .sort((a, b) => b.value - a.value),
);

// Beams and missiles have no per-shot alpha to test, so a loadout of only
// those has nothing to put in the check.
const hasTestableGuns = computed(
  () => collectLoadoutWeapons(props.hardpoints).length > 0,
);

const openPenetrationCheck = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Models/PenetrationCheckModal/index.vue"),
    wide: true,
    props: {
      modelName: props.modelName,
      hardpoints: props.hardpoints,
    },
  });
};

const hoveredControl = ref<string | null>(null);

const controlColors: Record<ControlGroup, string> = {
  pilot: "#f5b800",
  manned: "#7cb342",
  remote: "#ab47bc",
  pds: "#ef5350",
};

const controlComposition = computed(() =>
  CONTROL_GROUPS.map((key) => ({
    key,
    label: `labels.combat.controlGroups.${key}`,
    color: controlColors[key],
    value: stats.value.dpsByControl[key],
  })).filter((entry) => entry.value > 0),
);

// A ship whose every gun is the pilot's has nothing to split.
const showControlComposition = computed(() =>
  controlComposition.value.some((entry) => entry.key !== "pilot"),
);
</script>

<template>
  <MetricsCard
    v-if="loading || stats.hasData"
    :title="t('labels.combat.title')"
    :loading="loading"
    class="combat-panel"
  >
    <div v-if="stats.weaponCount" class="metrics-card__hero">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">
          {{ t("labels.combat.dps") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ dmg(animatedDps) }}
          <span class="metrics-card__tile__unit">DPS</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.combat.dpsSub", { count: stats.weaponCount }) }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.combat.sustained") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ dmg(animatedSustained) }}
          <span class="metrics-card__tile__unit">DPS</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.combat.sustainedSub") }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.combat.alpha") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ dmg(animatedAlpha) }}
          <span class="metrics-card__tile__unit">DMG</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.combat.alphaSub") }}
        </div>
      </div>
    </div>

    <div v-if="stats.missileDamage" class="metrics-card__aux">
      <span class="metrics-card__aux-label">
        {{ t("labels.combat.missileDamage") }}
      </span>
      <span class="metrics-card__aux-value">
        {{ toNumber(round(stats.missileDamage), "integer") }}
      </span>
    </div>

    <div v-if="stats.maxArmedMissiles" class="metrics-card__aux">
      <span class="metrics-card__aux-label">
        {{ t("labels.combat.armedMissiles") }}
      </span>
      <span class="metrics-card__aux-value">
        {{ stats.maxArmedMissiles }}
        <span
          v-if="typeof stats.launchCooldown === 'number'"
          class="metrics-card__aux-sub"
        >
          ·
          {{
            t("labels.combat.armedMissilesSub", {
              cooldown: stats.launchCooldown
                ? toNumber(stats.launchCooldown)
                : "0",
            })
          }}
        </span>
      </span>
    </div>

    <template v-if="stats.weaponCount">
      <div class="metrics-card__section-label">
        {{ t("labels.combat.composition") }}
      </div>
      <CompositionBar
        :segments="composition"
        :highlighted="hoveredType"
        @highlight="hoveredType = $event"
      />
    </template>

    <template v-if="showControlComposition">
      <div class="metrics-card__section-label">
        {{ t("labels.combat.controlComposition") }}
      </div>
      <CompositionBar
        :segments="controlComposition"
        :highlighted="hoveredControl"
        @highlight="hoveredControl = $event"
      />
    </template>

    <div v-if="hasTestableGuns" class="metrics-card__actions">
      <button
        type="button"
        class="metrics-card__toggle"
        @click="openPenetrationCheck"
      >
        {{ t("labels.combat.openPenetrationCheck") }}
      </button>
    </div>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">{{ t("labels.combat.hint") }}</span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.metrics-card__aux-sub {
  font-family: inherit;
  font-size: 12px;
  font-weight: 400;
  color: var(--color-text-dim);
}
</style>
