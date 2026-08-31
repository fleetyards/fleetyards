<script lang="ts">
export default {
  name: "ModelDeflectionCheckModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import type { Hardpoint } from "@/services/fyApi";
import { useComponentWeapons as useComponentWeaponsQuery } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useArmorStats } from "@/frontend/composables/useArmorStats";
import { useShieldStats } from "@/frontend/composables/useShieldStats";
import {
  useDeflectionCheck,
  absorptionAtHealth,
  deflectionAtHealth,
  DEFLECTION_DAMAGE_TYPES,
  type DeflectionResult,
} from "@/frontend/composables/useDeflectionCheck";

type Props = {
  modelName?: string;
  hardpoints?: Hardpoint[];
};

const props = withDefaults(defineProps<Props>(), {
  modelName: "",
  hardpoints: () => [],
});

const { t, toNumber } = useI18n();

const armor = useArmorStats(() => props.hardpoints);
const shield = useShieldStats(() => props.hardpoints);

// Percent of shield health remaining; drives how much of each damage type the
// shields still soak.
const shieldHealth = ref(100);
const armorHealth = ref(100);
const sizeFilter = ref<string | null>(null);
const classFilter = ref<string[]>([]);

const { data: weapons, isLoading } = useComponentWeaponsQuery();

const selectable = computed(() =>
  (weapons.value || []).filter(
    (weapon) =>
      !weapon.beam &&
      Object.values(weapon.damagePerShot ?? {}).some(
        (value) => (value ?? 0) > 0,
      ),
  ),
);

const sizes = computed(() => {
  const present = new Set(
    selectable.value
      .map((weapon) => weapon.size)
      .filter((size): size is string => !!size),
  );

  return [...present].sort((a, b) => Number(a) - Number(b));
});

// "BallisticGatling" -> "Ballistic Gatling"; the game files give us the class
// as a bare CamelCase tag with no display form.
const humanizeClass = (value: string) =>
  value.replace(/([a-z])([A-Z])/g, "$1 $2");

// Built from whatever classes the response actually contains, so the filter
// stays correct as the game data changes.
const classOptions = computed(() => {
  const present = new Set(
    selectable.value
      .map((weapon) => weapon.weaponClass)
      .filter((value): value is string => !!value),
  );

  return [...present]
    .sort()
    .map((value) => ({ label: humanizeClass(value), value }));
});

const filtered = computed(() =>
  (weapons.value || []).filter(
    (weapon) =>
      (!sizeFilter.value || weapon.size === sizeFilter.value) &&
      (!classFilter.value.length ||
        (!!weapon.weaponClass &&
          classFilter.value.includes(weapon.weaponClass))),
  ),
);

const check = useDeflectionCheck(
  filtered,
  armor,
  shield,
  () => shieldHealth.value / 100,
  () => armorHealth.value / 100,
);

// Live readouts mirroring erkul: both pools and their per-type figures scale
// with the sliders, so the effect of dropping either is visible at a glance.
const shieldReadout = computed(() => ({
  hp: shield.value.totalHp * (shieldHealth.value / 100),
  types: DEFLECTION_DAMAGE_TYPES.filter(({ key }) => key !== "thermal").map(
    ({ key, label }) => ({
      key,
      label,
      value:
        shieldHealth.value > 0
          ? absorptionAtHealth(shield.value, key, shieldHealth.value / 100)
          : 0,
    }),
  ),
}));

const armorReadout = computed(() => ({
  hp: armor.value.health * (armorHealth.value / 100),
  types: DEFLECTION_DAMAGE_TYPES.filter(({ key }) => key !== "thermal").map(
    ({ key, label }) => ({
      key,
      label,
      value: deflectionAtHealth(armor.value, key, armorHealth.value / 100),
    }),
  ),
}));

const round = (value: number) => Math.round(value);
// `toNumber` renders any falsy value as "N/A", which is wrong for a genuine
// zero — nothing absorbed is a real result, not missing data.
const num = (value: number) => (value ? toNumber(value, "integer") : "0");

// Bars run out from a centre line: deflected to the left, piercing to the
// right. Margins span a couple of orders of magnitude (a size 1 repeater barely
// clears the threshold, a size 5 cannon buries it), so a linear scale collapses
// almost every row into an invisible sliver — square-root keeps the small ones
// legible while the big ones still read as big.
const scale = computed(() =>
  check.value.results.reduce(
    (max, entry) => Math.max(max, Math.abs(entry.margin ?? 0)),
    1,
  ),
);

const barWidth = (margin: number) => {
  const ratio = Math.sqrt(Math.min(Math.abs(margin) / scale.value, 1));
  return `${Math.max(ratio * 100, 4)}%`;
};

// Absorbed weapons have no `best` type, so fall back to their heaviest hit.
const topRaw = (entry: DeflectionResult) =>
  entry.types.reduce((max, type) => Math.max(max, type.raw), 0);

const hovered = ref<string | null>(null);

const detail = computed(
  () =>
    check.value.results.find((entry) => entry.weapon.id === hovered.value) ??
    null,
);
</script>

<template>
  <Modal :title="t('labels.deflectionCheck.title')">
    <div class="deflection-modal">
      <p class="intro">
        <strong>{{ modelName }}</strong>
        {{ t("labels.deflectionCheck.intro") }}
      </p>

      <div v-if="!armor.hasData" class="empty">
        {{ t("labels.deflectionCheck.noArmor") }}
      </div>

      <template v-else>
        <div class="pools">
          <div class="pool">
            <div class="pool__head">
              <span class="pool__label">
                {{ t("labels.deflectionCheck.shieldHealth") }}
              </span>
              <span class="pool__pct">{{ shieldHealth }}%</span>
            </div>
            <input
              v-model.number="shieldHealth"
              type="range"
              min="0"
              max="100"
              step="1"
              class="pool__range"
            />
            <div class="pool__stats">
              <span class="pool__hp">
                HP {{ num(round(shieldReadout.hp)) }}
              </span>
              <span class="pool__kind">
                {{ t("labels.deflectionCheck.absorb") }}
              </span>
              <span
                v-for="type in shieldReadout.types"
                :key="type.key"
                class="pool__stat"
              >
                {{ t(type.label) }}
                <strong>{{ Math.round(type.value * 100) }}%</strong>
              </span>
            </div>
          </div>

          <div class="pool">
            <div class="pool__head">
              <span class="pool__label">
                {{ t("labels.deflectionCheck.armorHealth") }}
              </span>
              <span class="pool__pct">{{ armorHealth }}%</span>
            </div>
            <input
              v-model.number="armorHealth"
              type="range"
              min="0"
              max="100"
              step="1"
              class="pool__range"
            />
            <div class="pool__stats">
              <span class="pool__hp">
                HP {{ num(round(armorReadout.hp)) }}
              </span>
              <span class="pool__kind">
                {{ t("labels.deflectionCheck.defl") }}
              </span>
              <span
                v-for="type in armorReadout.types"
                :key="type.key"
                class="pool__stat"
              >
                {{ t(type.label) }}
                <strong>{{ Math.round(type.value) }}</strong>
              </span>
            </div>
          </div>
        </div>

        <div class="controls">
          <BaseSelect
            v-model="classFilter"
            :options="classOptions"
            :label="t('labels.deflectionCheck.type')"
            name="weapon-class"
            class="type-filter"
            multiple
            inline
            searchable
            no-label
          />

          <div
            class="sizes"
            role="group"
            :aria-label="t('labels.deflectionCheck.size')"
          >
            <button
              type="button"
              class="sizes__btn"
              :class="{ 'sizes__btn--active': sizeFilter === null }"
              :aria-pressed="sizeFilter === null"
              @click="sizeFilter = null"
            >
              {{ t("labels.deflectionCheck.allSizes") }}
            </button>
            <button
              v-for="size in sizes"
              :key="size"
              type="button"
              class="sizes__btn"
              :class="{ 'sizes__btn--active': sizeFilter === size }"
              :aria-pressed="sizeFilter === size"
              @click="sizeFilter = size"
            >
              S{{ size }}
            </button>
          </div>
        </div>

        <div class="tally">
          <template v-if="check.absorbedCount">
            <span class="tally__absorbed">
              {{ num(check.absorbedCount) }}
            </span>
            {{ t("labels.deflectionCheck.absorbed") }}
            <span class="tally__sep">·</span>
          </template>
          <span class="tally__deflected">
            {{ num(check.deflectedCount) }}
          </span>
          {{ t("labels.deflectionCheck.deflected") }}
          <span class="tally__sep">·</span>
          <span class="tally__pierce">
            {{ num(check.pierceCount) }}
          </span>
          {{ t("labels.deflectionCheck.pierce") }}
        </div>

        <Loader :loading="isLoading" relative />

        <template v-if="!isLoading">
          <div class="table-wrap">
            <table class="dtable">
              <colgroup>
                <col class="dtable__col-name" />
                <col class="dtable__col-bar" />
                <col class="dtable__col-num" />
                <col class="dtable__col-num" />
              </colgroup>
              <thead>
                <tr>
                  <th>{{ t("labels.deflectionCheck.weapon") }}</th>
                  <th class="center">
                    {{ t("labels.deflectionCheck.boundary") }}
                  </th>
                  <th class="num">{{ t("labels.deflectionCheck.margin") }}</th>
                  <th class="num">{{ t("labels.deflectionCheck.alpha") }}</th>
                </tr>
              </thead>
              <tbody>
                <template
                  v-for="(entry, index) in check.results"
                  :key="entry.weapon.id"
                >
                  <tr
                    v-if="
                      index > 0 &&
                      entry.outcome !== check.results[index - 1].outcome &&
                      entry.outcome !== 'absorbed'
                    "
                    class="dtable__divider"
                  >
                    <td colspan="4">
                      {{
                        entry.outcome === "pierces"
                          ? t("labels.deflectionCheck.threshold")
                          : t("labels.deflectionCheck.reachesArmor")
                      }}
                    </td>
                  </tr>

                  <tr
                    class="dtable__row"
                    @mouseenter="hovered = entry.weapon.id"
                    @mouseleave="hovered = null"
                  >
                    <td class="dtable__name">
                      <span class="dtable__title">{{ entry.weapon.name }}</span>
                      <span class="dtable__meta">
                        <span v-if="entry.weapon.size" class="dtable__size">
                          S{{ entry.weapon.size }}
                        </span>
                        <span v-if="entry.weapon.manufacturerCode">
                          {{ entry.weapon.manufacturerCode }}
                        </span>
                        <span v-if="entry.best" class="dtable__type">
                          {{ t(entry.best.label) }}
                        </span>
                      </span>
                    </td>

                    <td>
                      <span
                        v-if="entry.margin === null"
                        class="dtable__shielded"
                      >
                        {{ t("labels.deflectionCheck.stoppedByShields") }}
                      </span>
                      <span v-else class="bar">
                        <span class="bar__half">
                          <span
                            v-if="entry.outcome === 'deflected'"
                            class="bar__fill bar__fill--deflect"
                            :style="{ width: barWidth(entry.margin) }"
                          />
                        </span>
                        <span class="bar__half bar__half--right">
                          <span
                            v-if="entry.outcome === 'pierces'"
                            class="bar__fill bar__fill--pierce"
                            :style="{ width: barWidth(entry.margin) }"
                          />
                        </span>
                      </span>
                    </td>

                    <td class="num" :class="`margin--${entry.outcome}`">
                      <template v-if="entry.margin === null">—</template>
                      <template v-else>
                        {{ entry.margin > 0 ? "+" : ""
                        }}{{ round(entry.margin) }}
                      </template>
                    </td>

                    <td class="num dtable__alpha">
                      {{ num(round(entry.best?.raw ?? topRaw(entry))) }}
                    </td>
                  </tr>
                </template>
              </tbody>
            </table>
          </div>

          <div class="detail">
            <template v-if="detail">
              <span class="detail__name">{{ detail.weapon.name }}</span>
              <span
                v-for="type in detail.types"
                :key="type.key"
                class="detail__type"
              >
                {{ t(type.label) }}
                <template v-if="type.absorbed">
                  <span class="detail__absorbed">
                    {{ t("labels.deflectionCheck.absorbed") }}
                  </span>
                </template>
                <template v-else>
                  <strong>{{ round(type.effective) }}</strong>
                  <span class="detail__raw">({{ round(type.raw) }} raw)</span>
                </template>
                {{ t("labels.deflectionCheck.versus") }}
                {{ round(type.deflection) }}
              </span>
              <span
                class="detail__verdict"
                :class="`detail__verdict--${detail.outcome}`"
              >
                {{ t(`labels.deflectionCheck.verdict.${detail.outcome}`) }}
              </span>
            </template>
            <span v-else class="detail__hint">
              {{ t("labels.deflectionCheck.hoverHint") }}
            </span>
          </div>

          <p class="note">{{ t("labels.deflectionCheck.note") }}</p>
        </template>
      </template>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
.intro {
  font-size: 12px;
  color: $gray-light;
  margin-bottom: 14px;
}

.empty {
  padding: 20px;
  text-align: center;
  font-size: 13px;
  color: $gray;
}

// Filter and size buttons share one full-width row; the tally sits on its own
// line below so neither has to compete with it for space.
.controls {
  display: flex;
  align-items: stretch;
  gap: 10px;
  margin-bottom: 8px;

  @media (max-width: 640px) {
    flex-wrap: wrap;
  }
}

.pools {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin-bottom: 14px;

  @media (max-width: 640px) {
    grid-template-columns: 1fr;
  }
}

.pool {
  padding: 10px 12px;
  background: $gray-black;
  border: 1px solid rgba($gray-light, 0.28);
  border-radius: 6px;

  &__head {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 8px;
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 9px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: $gray;
  }

  &__pct {
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 700;
    font-size: 15px;
    color: $gold;
    font-variant-numeric: tabular-nums;
  }

  &__range {
    display: block;
    width: 100%;
    margin: 6px 0 8px;
    accent-color: $gold;
    cursor: ew-resize;
  }

  &__stats {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 4px 10px;
    font-size: 11px;
    color: $gray;
  }

  &__hp {
    color: $gray-light;
    font-variant-numeric: tabular-nums;

    strong {
      color: lighten($text-color, 15%);
    }
  }

  &__kind {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 8.5px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }

  &__stat {
    font-variant-numeric: tabular-nums;

    strong {
      color: lighten($text-color, 15%);
    }
  }
}

.type-filter {
  flex: 0 0 210px;
  min-width: 0;
  margin: 0;

  @media (max-width: 640px) {
    flex: 1 1 100%;
  }
}

.sizes {
  display: flex;
  flex: 1 1 auto;
  min-width: 0;
  gap: 4px;

  &__btn {
    // Share the remaining width evenly rather than sitting cramped at the left.
    flex: 1 1 0;
    height: 43px;
    min-width: 0;
    padding: 0 6px;
    border-radius: 4px;
    border: 1px solid rgba($gray-light, 0.28);
    background: $gray-black;
    color: $gray-light;
    font-size: 13px;
    font-variant-numeric: tabular-nums;
    cursor: pointer;
    transition:
      color 0.15s ease,
      border-color 0.15s ease;

    &:hover {
      color: lighten($text-color, 15%);
      border-color: rgba($gray-light, 0.5);
    }

    &--active {
      border-color: rgba($gold, 0.6);
      color: $gold;
    }
  }
}

.tally {
  margin-bottom: 14px;
  text-align: right;
  font-size: 12px;
  color: $gray;

  &__absorbed {
    font-weight: 700;
    color: $primary;
  }

  &__deflected {
    font-weight: 700;
    color: $success;
  }

  &__pierce {
    font-weight: 700;
    color: $danger;
  }

  &__sep {
    margin: 0 4px;
  }
}

// A fixed table layout is the whole point here: column widths are decided by
// the colgroup alone, so no amount of long weapon names or six-figure margins
// can push the table wider than the modal.
// The modal body is itself a scroll container, so an inner scroller with its
// own max-height gives two nested scrollbars. Capping the wrapper at the same
// height means the body never scrolls and only the weapon list does.
.deflection-modal {
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 15rem);
}

.table-wrap {
  flex: 1 1 auto;
  min-height: 0;
  max-width: 100%;
  overflow-x: hidden;
  overflow-y: auto;
}

.dtable {
  width: 100%;
  table-layout: fixed;
  border-collapse: collapse;
  font-size: 13px;

  &__col-name {
    width: auto;
  }

  &__col-bar {
    width: 34%;
  }

  &__col-num {
    width: 76px;
  }

  th {
    position: sticky;
    top: 0;
    z-index: 1;
    background: $panel-bg;
    text-align: left;
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 400;
    font-size: 8.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: $gray;
    padding: 0 10px 6px 0;
    border-bottom: 1px solid rgba($gray-light, 0.28);
  }

  td {
    padding: 7px 10px 7px 0;
    border-bottom: 1px solid rgba($gray-light, 0.18);
    color: $text-color;
    overflow: hidden;
  }

  .num {
    text-align: right;
    padding-right: 0;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  .center {
    text-align: center;
  }

  &__row {
    cursor: default;

    &:hover td {
      background: rgba($gray-light, 0.06);
    }
  }

  &__divider td {
    padding: 6px 0;
    text-align: center;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 8.5px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: $gray;
    border-bottom: 0;
    border-top: 1px dashed rgba($gray-light, 0.4);
  }

  &__name {
    // Long names ellipsis rather than widening the column.
    max-width: 0;
  }

  &__title {
    display: block;
    font-size: 13.5px;
    color: lighten($text-color, 15%);
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }

  &__meta {
    display: flex;
    flex-wrap: nowrap;
    gap: 7px;
    font-size: 11px;
    color: $gray;
    overflow: hidden;
    white-space: nowrap;
  }

  &__size {
    color: $gray-light;
  }

  &__type {
    text-transform: uppercase;
    letter-spacing: 0.08em;
  }

  &__shielded {
    display: block;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 8.5px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: $primary;
    text-align: center;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  &__alpha {
    font-size: 14px;
    font-weight: 700;
    color: lighten($text-color, 15%);
  }
}

.margin {
  &--absorbed {
    color: $gray;
  }

  &--deflected {
    color: $success;
    font-weight: 700;
  }

  &--pierces {
    color: $danger;
    font-weight: 700;
  }
}

// Two halves meeting at the deflection threshold: deflected fills leftwards
// from the centre, piercing fills rightwards.
.bar {
  display: flex;
  align-items: center;
  height: 10px;

  &__half {
    flex: 1 1 0;
    display: flex;
    height: 100%;
    min-width: 0;
    justify-content: flex-end;
    border-right: 1px solid rgba($gray-light, 0.45);

    &--right {
      justify-content: flex-start;
      border-right: 0;
    }
  }

  &__fill {
    height: 100%;
    border-radius: 2px;

    &--deflect {
      background: $success;
    }

    &--pierce {
      background: $danger;
    }
  }
}

.detail {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 12px;
  margin-top: 12px;
  padding: 10px 12px;
  background: $gray-black;
  border: 1px solid rgba($gray-light, 0.28);
  border-radius: 6px;
  font-size: 11.5px;
  color: $gray-light;
  min-height: 40px;

  &__name {
    font-weight: 700;
    color: lighten($text-color, 15%);
  }

  &__raw {
    color: $gray;
  }

  &__absorbed {
    color: $primary;
    text-transform: uppercase;
    font-size: 9.5px;
    letter-spacing: 0.1em;
  }

  &__verdict {
    margin-left: auto;
    padding: 2px 8px;
    border-radius: 3px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 8.5px;
    letter-spacing: 0.12em;
    text-transform: uppercase;

    &--pierces {
      background: rgba($danger, 0.18);
      color: $danger;
    }

    &--deflected {
      background: rgba($success, 0.18);
      color: $success;
    }

    &--absorbed {
      background: rgba($primary, 0.18);
      color: $primary;
    }
  }

  &__hint {
    color: $gray;
  }
}

.note {
  margin: 12px 0 0;
  font-size: 11px;
  color: $gray;
}
</style>
