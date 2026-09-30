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
    <div class="check-modal">
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
@import "@/frontend/components/Models/defenseCheck";
</style>
