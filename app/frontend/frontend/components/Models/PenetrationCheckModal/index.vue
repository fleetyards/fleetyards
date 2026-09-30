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

type Props = {
  modelName?: string;
  hardpoints?: Hardpoint[];
};

const props = withDefaults(defineProps<Props>(), {
  modelName: "",
  hardpoints: () => [],
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

const loadoutWeapons = computed(() => collectLoadoutWeapons(props.hardpoints));

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

const { data: defenses, isLoading } = useModelDefensesQuery();

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
              :class="{ 'sizes__btn--active': sizeFilter === size }"
              :aria-pressed="sizeFilter === size"
              @click="sizeFilter = size"
            >
              {{ humanizeSize(size) }}
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
                  <th>{{ t("labels.penetrationCheck.ship") }}</th>
                  <th class="center">
                    {{ t("labels.deflectionCheck.boundary") }}
                  </th>
                  <th class="num">{{ t("labels.deflectionCheck.margin") }}</th>
                  <th class="num">{{ t("labels.deflectionCheck.defl") }}</th>
                </tr>
              </thead>
              <tbody>
                <template
                  v-for="(entry, index) in check.results"
                  :key="entry.model.id"
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
            </template>
            <span v-else class="detail__hint">
              {{ t("labels.penetrationCheck.hoverHint") }}
            </span>
          </div>

          <p class="note">{{ t("labels.penetrationCheck.note") }}</p>
        </template>
      </template>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/defenseCheck";

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
