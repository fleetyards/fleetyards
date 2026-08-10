<script lang="ts">
export default {
  name: "ModelDefenseMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Hardpoint } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useShieldStats } from "@/frontend/composables/useShieldStats";
import { useArmorStats } from "@/frontend/composables/useArmorStats";

type Props = {
  hardpoints?: Hardpoint[];
  modelName?: string;
};

const props = withDefaults(defineProps<Props>(), {
  hardpoints: () => [],
  modelName: "",
});

const { t, toNumber } = useI18n();

const comlink = useComlink();

const shield = useShieldStats(() => props.hardpoints);
const armor = useArmorStats(() => props.hardpoints);

const round = (value: number) => Math.round(value);
// `toNumber` renders any falsy value as "N/A", which is wrong for a genuine
// zero — nothing absorbed is a real result, not missing data.
const num = (value: number) => (value ? toNumber(value, "integer") : "0");

const hasData = computed(() => shield.value.hasData || armor.value.hasData);

const percent = (value: number) => `${Math.round(value * 100)}%`;

const signed = (value: number) =>
  `${value > 0 ? "+" : ""}${Math.round(value * 100)}%`;

const absorptionLabel = (entry: { min: number; max: number }) =>
  entry.min === entry.max
    ? percent(entry.max)
    : `${percent(entry.min)} – ${percent(entry.max)}`;

const openDeflectionCheck = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Models/DeflectionCheckModal/index.vue"),
    wide: true,
    props: {
      modelName: props.modelName,
      hardpoints: props.hardpoints,
    },
  });
};
</script>

<template>
  <MetricsCard
    v-if="hasData"
    :title="t('labels.defense.title')"
    class="defense-panel"
  >
    <div v-if="shield.hasData" class="metrics-card__hero">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">
          {{ t("labels.defense.shieldHp") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ num(round(shield.totalHp)) }}
          <span class="metrics-card__tile__unit">HP</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.defense.shieldHpSub", { count: shield.shieldCount }) }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.defense.shieldRegen") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ num(round(shield.totalRegen)) }}
          <span class="metrics-card__tile__unit">HP/s</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.defense.shieldRegenSub") }}
        </div>
      </div>
    </div>

    <dl class="stat-rows">
      <template v-if="shield.resistances.length">
        <dt>{{ t("labels.defense.shieldResistances") }}</dt>
        <dd>
          <span
            v-for="entry in shield.resistances"
            :key="entry.key"
            class="chip"
            :data-type="entry.key"
          >
            <span class="chip__label">{{ t(entry.label) }}</span>
            <span class="chip__value">{{ percent(entry.value) }}</span>
          </span>
        </dd>
      </template>

      <template v-if="shield.absorptions.length">
        <dt>{{ t("labels.defense.shieldAbsorption") }}</dt>
        <dd>
          <span
            v-for="entry in shield.absorptions"
            :key="entry.key"
            class="chip"
            :data-type="entry.key"
            :data-leaky="entry.max < 1 ? 'true' : undefined"
          >
            <span class="chip__label">{{ t(entry.label) }}</span>
            <span class="chip__value">{{ absorptionLabel(entry) }}</span>
          </span>
        </dd>
      </template>
    </dl>

    <template v-if="armor.hasData">
      <div class="metrics-card__divider" />

      <div class="armor-head">
        <span class="armor-head__label">{{ t("labels.defense.armor") }}</span>
        <span v-if="armor.health" class="armor-head__value">
          {{ num(round(armor.health)) }}
          <span class="armor-head__unit">HP</span>
        </span>
      </div>

      <dl class="stat-rows">
        <template v-if="armor.deflections.length">
          <dt>{{ t("labels.defense.deflection") }}</dt>
          <dd>
            <span
              v-for="entry in armor.deflections"
              :key="entry.key"
              class="chip"
              :data-type="entry.key"
            >
              <span class="chip__label">{{ t(entry.label) }}</span>
              <span class="chip__value">
                {{ num(entry.value) }}
              </span>
            </span>
          </dd>
        </template>

        <template v-if="armor.reductions.length">
          <dt>{{ t("labels.defense.armorReduction") }}</dt>
          <dd>
            <span
              v-for="entry in armor.reductions"
              :key="entry.key"
              class="chip"
              :data-type="entry.key"
              :data-negative="entry.value < 0 ? 'true' : undefined"
            >
              <span class="chip__label">{{ t(entry.label) }}</span>
              <span class="chip__value">{{ percent(entry.value) }}</span>
            </span>
          </dd>
        </template>

        <template v-if="armor.selfResistances.length">
          <dt>{{ t("labels.defense.armorSelfResistance") }}</dt>
          <dd>
            <span
              v-for="entry in armor.selfResistances"
              :key="entry.key"
              class="chip"
              :data-type="entry.key"
              :data-negative="entry.value < 0 ? 'true' : undefined"
            >
              <span class="chip__label">{{ t(entry.label) }}</span>
              <span class="chip__value">{{ percent(entry.value) }}</span>
            </span>
          </dd>
        </template>

        <template v-if="armor.signatures.length">
          <dt>{{ t("labels.defense.armorSignature") }}</dt>
          <dd>
            <span
              v-for="entry in armor.signatures"
              :key="entry.key"
              class="chip"
              :data-negative="entry.value > 0 ? 'true' : undefined"
            >
              <span class="chip__label">{{ t(entry.label) }}</span>
              <span class="chip__value">{{ signed(entry.value) }}</span>
            </span>
          </dd>
        </template>
      </dl>
    </template>

    <div v-if="armor.hasData" class="metrics-card__actions">
      <button
        type="button"
        class="metrics-card__toggle"
        @click="openDeflectionCheck"
      >
        {{ t("labels.defense.openDeflectionCheck") }}
      </button>
    </div>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">
        {{ t("labels.defense.hint") }}
      </span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

.stat-rows {
  display: grid;
  grid-template-columns: auto 1fr;
  align-items: baseline;
  gap: 8px 14px;
  margin: 0 0 4px;

  dt {
    font-size: 12px;
    font-weight: 400;
    color: $gray-light;
    white-space: nowrap;
  }

  dd {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: 6px;
    margin: 0;
  }

  @media (max-width: 480px) {
    grid-template-columns: 1fr;
    gap: 4px;

    dd {
      justify-content: flex-start;
      margin-bottom: 6px;
    }
  }
}

.chip {
  display: inline-flex;
  align-items: baseline;
  gap: 5px;
  padding: 3px 8px;
  background: $gray-black;
  border: 1px solid rgba($gray-light, 0.28);
  border-radius: 4px;
  white-space: nowrap;

  &__label {
    font-size: 10.5px;
    color: $gray;
  }

  &__value {
    font-size: 12px;
    font-weight: 700;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }

  &[data-type="energy"] .chip__label {
    color: $primary;
  }

  &[data-type="distortion"] .chip__label {
    color: $cyan;
  }

  &[data-type="thermal"] .chip__label {
    color: $warning;
  }

  // A type the shield fails to fully soak, or armor amplifies instead of
  // reducing — both are weaknesses worth spotting at a glance.
  &[data-leaky="true"] .chip__value,
  &[data-negative="true"] .chip__value {
    color: $danger;
  }
}

.armor-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 10px;

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: lighten($text-color, 10%);
  }

  &__value {
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 700;
    font-size: 15px;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }

  &__unit {
    font-size: 10px;
    font-weight: 400;
    color: $gray;
  }
}
</style>
