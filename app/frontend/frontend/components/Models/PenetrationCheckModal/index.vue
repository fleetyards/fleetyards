<script lang="ts">
export default {
  name: "ModelPenetrationCheckModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import type { Hardpoint } from "@/services/fyApi";
import { useModelDefenses as useModelDefensesQuery } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  collectLoadoutWeapons,
  penetrationTargets,
  usePenetrationCheck,
  type PenetrationResult,
} from "@/frontend/composables/usePenetrationCheck";
import {
  effectiveHp,
  killProfile,
  timeToKill,
} from "@/frontend/composables/useTimeToKill";
import { DEFLECTION_DAMAGE_TYPES } from "@/frontend/composables/useDeflectionCheck";

type Props = {
  modelName?: string;
  hardpoints?: Hardpoint[];
  // Share of the weapon pool the power allocation feeds, as on the combat card.
  powerRatio?: number;
};

const props = withDefaults(defineProps<Props>(), {
  modelName: "",
  hardpoints: () => [],
  powerRatio: 1,
});

const { t, toNumber } = useI18n();

// The same order the catalogue's size filter uses.
const SIZE_ORDER = [
  "vehicle",
  "snub",
  "small",
  "medium",
  "large",
  "extra_large",
  "capital",
];

const loadoutWeapons = computed(() =>
  collectLoadoutWeapons(props.hardpoints, props.powerRatio),
);

// Everything the loadout mounts starts selected; a click takes a gun out of
// (or back into) the comparison.
const deselected = ref<string[]>([]);

const toggleWeapon = (id: string) => {
  deselected.value = deselected.value.includes(id)
    ? deselected.value.filter((entry) => entry !== id)
    : [...deselected.value, id];
};

const selectedWeapons = computed(() =>
  loadoutWeapons.value.filter(
    (weapon) => !deselected.value.includes(weapon.id),
  ),
);

// Percent of the target's shield and armor health remaining.
const shieldHealth = ref(100);
const armorHealth = ref(100);
const sizeFilter = ref<string | null>(null);

const { data: defenses, isLoading, isError } = useModelDefensesQuery();

const targets = computed(() => penetrationTargets(defenses.value));

const sizes = computed(() => {
  const present = new Set(
    targets.value
      .map((target) => target.model.size)
      .filter((size): size is string => !!size),
  );

  return SIZE_ORDER.filter((size) => present.has(size));
});

const filteredTargets = computed(() =>
  targets.value.filter(
    (target) => !sizeFilter.value || target.model.size === sizeFilter.value,
  ),
);

const check = usePenetrationCheck(
  selectedWeapons,
  filteredTargets,
  () => shieldHealth.value / 100,
  () => armorHealth.value / 100,
);

const SORT_OPTIONS = ["margin", "ttk"] as const;

const sortBy = ref<(typeof SORT_OPTIONS)[number]>("margin");

const start = computed(() => ({
  shieldHealth: shieldHealth.value / 100,
  armorHealth: armorHealth.value / 100,
}));

const profiles = computed(
  () =>
    new Map(
      filteredTargets.value.map((target) => [
        target.model.id,
        killProfile(target.model, target.shield, target.armor),
      ]),
    ),
);

const kills = computed(
  () =>
    new Map(
      [...profiles.value].map(([id, profile]) => [
        id,
        timeToKill(profile, selectedWeapons.value, start.value),
      ]),
    ),
);

const killTime = (entry: PenetrationResult) =>
  kills.value.get(entry.model.id)?.kill ?? null;

// Ships the loadout never brings down sort after every kill, and ships with no
// hull health to measure after those.
const killRank = (time: number | null) => {
  if (time === null) return 2;
  return Number.isFinite(time) ? 0 : 1;
};

const byKillTime = (a: PenetrationResult, b: PenetrationResult) => {
  const timeA = killTime(a);
  const timeB = killTime(b);
  const rank = killRank(timeA) - killRank(timeB);

  if (rank !== 0 || killRank(timeA) !== 0) return rank;
  return timeA! - timeB!;
};

const rows = computed(() =>
  sortBy.value === "ttk"
    ? [...check.value.results].sort(byKillTime)
    : check.value.results,
);

// Tenths of a second under a minute, whole seconds as m:ss beyond it. Rounded
// before the branch so 59.97 s reads 1:00, not 60 s.
const formatTime = (seconds: number | null) => {
  if (seconds === null) return "—";
  if (!Number.isFinite(seconds)) return "∞";

  const tenths = Math.round(seconds * 10) / 10;
  if (tenths < 60) {
    return tenths
      ? toNumber(tenths, "seconds")
      : t("number.seconds", { count: 0 });
  }

  const whole = Math.round(seconds);
  return `${Math.floor(whole / 60)}:${String(whole % 60).padStart(2, "0")}`;
};

const humanizeSize = (size: string) => {
  const words = size.replace(/_/g, " ");
  return words.charAt(0).toUpperCase() + words.slice(1);
};

const round = (value: number) => Math.round(value);
// `toNumber` renders any falsy value as "N/A", which is wrong for a genuine
// zero — nothing pierced is a real result, not missing data.
const num = (value: number) => (value ? toNumber(value, "integer") : "0");

// Same square-root scale as the deflection check, so a hull that barely turns
// a gun away and one that buries it both stay legible.
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

const threshold = (entry: PenetrationResult) => entry.best?.best?.deflection;

const hovered = ref<string | null>(null);

const detail = computed(
  () =>
    check.value.results.find((entry) => entry.model.id === hovered.value) ??
    null,
);

// Effective HP does not depend on the guns, and only the hovered ship shows it.
const detailSurvival = computed(() => {
  const id = detail.value?.model.id;
  const profile = id ? profiles.value.get(id) : undefined;
  if (!id || !profile) return undefined;

  return {
    ehp: effectiveHp(profile, start.value),
    ttk: kills.value.get(id)!,
  };
});
</script>

<template>
  <Modal :title="t('labels.penetrationCheck.title')">
    <div class="check-modal">
      <p class="intro">
        <strong>{{ modelName }}</strong>
        {{ t("labels.penetrationCheck.intro") }}
      </p>

      <div v-if="!loadoutWeapons.length" class="empty">
        {{ t("labels.penetrationCheck.noWeapons") }}
      </div>

      <template v-else>
        <div
          class="weapons"
          role="group"
          :aria-label="t('labels.penetrationCheck.weapons')"
        >
          <button
            v-for="weapon in loadoutWeapons"
            :key="weapon.id"
            type="button"
            class="weapons__btn"
            data-test="penetration-weapon"
            :class="{
              'weapons__btn--active': !deselected.includes(weapon.id),
            }"
            :aria-pressed="!deselected.includes(weapon.id)"
            @click="toggleWeapon(weapon.id)"
          >
            <span v-if="weapon.count > 1" class="weapons__count">
              {{ weapon.count }}×
            </span>
            <span v-if="weapon.size" class="weapons__size">
              S{{ weapon.size }}
            </span>
            {{ weapon.name }}
          </button>
        </div>

        <div class="pools">
          <div class="pool">
            <div class="pool__head">
              <span class="pool__label">
                {{ t("labels.penetrationCheck.shieldHealth") }}
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
          </div>

          <div class="pool">
            <div class="pool__head">
              <span class="pool__label">
                {{ t("labels.penetrationCheck.armorHealth") }}
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
          </div>
        </div>

        <div class="controls">
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
              data-test="penetration-size"
              :class="{ 'sizes__btn--active': sizeFilter === size }"
              :aria-pressed="sizeFilter === size"
              @click="sizeFilter = size"
            >
              {{ humanizeSize(size) }}
            </button>
          </div>

          <div
            class="sizes"
            role="group"
            :aria-label="t('labels.penetrationCheck.sortBy')"
          >
            <button
              v-for="option in SORT_OPTIONS"
              :key="option"
              type="button"
              class="sizes__btn"
              data-test="penetration-sort"
              :class="{ 'sizes__btn--active': sortBy === option }"
              :aria-pressed="sortBy === option"
              @click="sortBy = option"
            >
              {{ t(`labels.penetrationCheck.sort.${option}`) }}
            </button>
          </div>
        </div>

        <div class="tally" data-test="penetration-tally">
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

        <div v-if="isError" class="empty" data-test="penetration-error">
          {{ t("texts.serverError") }}
        </div>

        <template v-else-if="!isLoading">
          <div class="table-wrap">
            <table class="dtable">
              <colgroup>
                <col class="dtable__col-name" />
                <col class="dtable__col-bar" />
                <col class="dtable__col-num" />
                <col class="dtable__col-num" />
                <col class="dtable__col-num" />
              </colgroup>
              <thead>
                <tr>
                  <th>{{ t("labels.penetrationCheck.ship") }}</th>
                  <th class="center">
                    {{ t("labels.deflectionCheck.boundary") }}
                  </th>
                  <th class="num">{{ t("labels.deflectionCheck.margin") }}</th>
                  <th class="num">{{ t("labels.deflectionCheck.defl") }}</th>
                  <th class="num">{{ t("labels.penetrationCheck.ttk") }}</th>
                </tr>
              </thead>
              <tbody>
                <template v-for="(entry, index) in rows" :key="entry.model.id">
                  <tr
                    v-if="
                      sortBy === 'margin' &&
                      index > 0 &&
                      entry.outcome !== rows[index - 1].outcome &&
                      entry.outcome !== 'absorbed'
                    "
                    class="dtable__divider"
                  >
                    <td colspan="5">
                      {{
                        entry.outcome === "pierces"
                          ? t("labels.deflectionCheck.threshold")
                          : t("labels.deflectionCheck.reachesArmor")
                      }}
                    </td>
                  </tr>

                  <tr
                    class="dtable__row"
                    data-test="penetration-row"
                    @mouseenter="hovered = entry.model.id"
                    @mouseleave="hovered = null"
                  >
                    <td class="dtable__name">
                      <span class="dtable__title">{{ entry.model.name }}</span>
                      <span class="dtable__meta">
                        <span v-if="entry.model.size" class="dtable__size">
                          {{ humanizeSize(entry.model.size) }}
                        </span>
                        <span v-if="entry.model.manufacturerCode">
                          {{ entry.model.manufacturerCode }}
                        </span>
                        <span v-if="entry.best?.best" class="dtable__type">
                          {{ t(entry.best.best.label) }}
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
                      <template v-if="threshold(entry) === undefined">
                        —
                      </template>
                      <template v-else>
                        {{ num(round(threshold(entry)!)) }}
                      </template>
                    </td>

                    <td class="num" data-test="penetration-ttk">
                      {{ formatTime(killTime(entry)) }}
                    </td>
                  </tr>
                </template>
              </tbody>
            </table>
          </div>

          <div class="detail">
            <template v-if="detail">
              <span class="detail__name">{{ detail.model.name }}</span>
              <span
                v-for="result in detail.weapons"
                :key="result.weapon.id"
                class="detail__type"
              >
                {{ result.weapon.name }}
                <template v-if="!result.best">
                  <span class="detail__absorbed">
                    {{ t("labels.deflectionCheck.absorbed") }}
                  </span>
                </template>
                <template v-else>
                  <strong>{{ round(result.best.effective) }}</strong>
                  {{ t("labels.deflectionCheck.versus") }}
                  {{ round(result.best.deflection) }}
                </template>
              </span>
              <span
                class="detail__verdict"
                :class="`detail__verdict--${detail.outcome}`"
              >
                {{ t(`labels.deflectionCheck.verdict.${detail.outcome}`) }}
              </span>
              <template v-if="detailSurvival">
                <span class="detail__break" />
                <span class="detail__name">
                  {{ t("labels.penetrationCheck.effectiveHp") }}
                </span>
                <span
                  v-for="type in DEFLECTION_DAMAGE_TYPES"
                  :key="type.key"
                  class="detail__type"
                  data-test="penetration-ehp"
                >
                  {{ t(type.label) }}
                  <strong>
                    <template v-if="detailSurvival.ehp[type.key] === null">
                      —
                    </template>
                    <template v-else>
                      {{ num(round(detailSurvival.ehp[type.key]!)) }}
                    </template>
                  </strong>
                </span>
                <span class="detail__type">
                  {{ t("labels.penetrationCheck.shieldsDown") }}
                  <strong>
                    {{ formatTime(detailSurvival.ttk.shieldsDown) }}
                  </strong>
                </span>
                <span class="detail__type">
                  {{ t("labels.penetrationCheck.ttk") }}
                  <strong>{{ formatTime(detailSurvival.ttk.kill) }}</strong>
                </span>
              </template>
            </template>
            <span v-else class="detail__hint">
              {{ t("labels.penetrationCheck.hoverHint") }}
            </span>
          </div>

          <p class="note">{{ t("labels.penetrationCheck.note") }}</p>
          <p class="note">{{ t("labels.penetrationCheck.ttkNote") }}</p>
        </template>
      </template>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/defenseCheck";

.detail__break {
  flex-basis: 100%;
  height: 0;
}

.weapons {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-bottom: 10px;

  &__btn {
    padding: 6px 10px;
    border-radius: 4px;
    border: 1px solid rgba($gray-light, 0.28);
    background: $gray-black;
    color: $gray;
    font-size: 12px;
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

  &__count,
  &__size {
    margin-right: 4px;
    font-variant-numeric: tabular-nums;
  }
}
</style>
