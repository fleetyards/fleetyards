<script lang="ts">
export default {
  name: "BlueprintSlot",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  useQualityRamp,
  NEUTRAL_QUALITY,
} from "@/frontend/composables/useQualityRamp";
import {
  useMaterialStock,
  type MaterialStock,
} from "@/frontend/composables/useMaterialStock";
import { type BlueprintCostSlot } from "@/services/fyApi";

type Props = {
  slotData: BlueprintCostSlot;
  quality: number;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  "update:quality": [value: number];
}>();

const { t } = useI18n();

const option = computed(() => props.slotData.options?.[0]);

// 4,267 of the 4,289 slots in the current build gate at 0 or 1, which is no
// gate at all. Badging every one of them would bury the 22 that ask for
// something.
const gate = computed<number | undefined>(() => {
  const min = option.value?.minQuality;

  // Nullable in the schema, and 0 or 1 on 4,267 of the 4,289 slots — which is
  // no gate at all. Only a real one becomes a number here.
  if (min === undefined || min === null || min <= 1) return undefined;

  return min;
});

// How much of the material the slot takes. A resource is measured in SCU and
// an item in whole pieces, and the quantity is nullable in the schema -- a
// cost line with no amount still names its material rather than printing an
// empty figure.
const amount = computed(() => {
  const value = option.value;
  if (!value) return undefined;

  const quantity = value.quantity;
  if (quantity === undefined || quantity === null) return undefined;

  return value.type === "resource"
    ? t("labels.blueprint.scu", { amount: quantity })
    : // The game counts gems in whole pieces, and the column is a decimal, so
      // a count of 170 arrived as "170.0x".
      t("labels.blueprint.pieces", { count: Math.round(quantity) });
});

const belowGate = computed(
  () => gate.value !== undefined && props.quality < gate.value,
);

// What the reader already holds of this slot's material, if they are signed
// in and keep inventories.
const { forCommodity } = useMaterialStock();

const held = computed(() =>
  forCommodity(
    option.value?.commodity?.id,
    option.value?.quantity,
    option.value?.type,
  ),
);

// "101 SCU on Avenger Titan" -- the material is named by the slot already, so
// repeating it here said the same word twice on one line.
const amountOf = (entry: MaterialStock) =>
  entry.unit === "scu"
    ? t("labels.blueprint.scu", { amount: entry.quantity })
    : t("labels.blueprint.pieces", { count: Math.round(entry.quantity) });

const placeOf = (entry: MaterialStock) =>
  entry.vehicleName || entry.inventoryName || "";

const prepositionOf = (entry: MaterialStock) =>
  entry.vehicleName
    ? t("labels.blueprint.heldOn")
    : t("labels.blueprint.heldIn");

// A ship's inventory is not reachable by slug -- `addressable_by_slug` covers
// the hand-made ones only -- so linking one would land on a not-found. It is
// named without a link instead.
const placeRoute = (entry: MaterialStock) => {
  if (entry.vehicleName || !entry.inventorySlug) return undefined;

  if (entry.ownerSlug) {
    return {
      name: "fleet-logistics-inventory",
      params: { slug: entry.ownerSlug, inventory: entry.inventorySlug },
    };
  }

  return {
    name: "hangar-inventory",
    params: { inventory: entry.inventorySlug },
  };
};

// One list, not two: where a holding sits is the row's own last column, so a
// fleet's store is told apart by name rather than by a heading of its own.
// Three rows did not earn two headings.
const heldRows = computed(() => [
  ...held.value.own.map((entry) => ({
    entry,
    tag: t("labels.blueprint.fromHangar"),
  })),
  ...held.value.fleet.map((entry) => ({ entry, tag: entry.ownerName || "" })),
]);

// The grades actually held, placed on the quality track. This is the question
// the panel exists to answer -- where what I have sits on the ramp -- and a
// list beside the slider could only ever state it in numbers.
const marks = computed(() => {
  const seen = new Set<number>();

  return heldRows.value
    .flatMap(({ entry }) => entry.qualities)
    .filter((grade) => !seen.has(grade) && seen.add(grade))
    .sort((one, other) => one - other)
    .map((grade) => ({ grade, left: `${(grade / 1000) * 100}%` }));
});

// The row whose grade the slider is sitting on. Clicking a row applies its
// grade, so the one in force reads as the chosen one rather than leaving the
// reader to match a number against the slider.
const isPicked = (entry: MaterialStock) =>
  entry.qualities.includes(props.quality);

// Clicking the grade already in force clears it rather than doing nothing:
// a holding can be tried and put back without hunting for 500 on the slider.
const applyGrade = (grade: number) => {
  emit("update:quality", grade === props.quality ? NEUTRAL_QUALITY : grade);
};

const { ramps } = useQualityRamp(
  () => props.slotData.modifiers || [],
  () => props.quality,
  () => !belowGate.value,
);

// A number input reports "" mid-edit -- cleared, or a lone "-" -- and
// Number("") is 0, which would slam the slot to zero under the cursor. An
// unparseable value leaves it where it was.
const onQuality = (event: Event) => {
  const raw = (event.target as HTMLInputElement).value;
  if (raw === "") return;

  const parsed = Number(raw);
  if (!Number.isFinite(parsed)) return;

  emit("update:quality", Math.min(Math.max(Math.round(parsed), 0), 1000));
};
</script>

<template>
  <div class="blueprint-slot">
    <div class="blueprint-slot__head">
      <span class="blueprint-slot__name">{{ slotData.name }}</span>
      <span v-if="gate" class="blueprint-slot__gate">
        {{ t("labels.blueprint.minQuality", { quality: gate }) }}
      </span>

      <span v-if="option" class="blueprint-slot__material">
        <span v-if="amount" class="blueprint-slot__amount">{{ amount }}</span>
        <!-- A material the commodity catalogue has no row for still says
             which material it is: the key is what the game names. -->
        <span v-if="option.commodity">{{ option.commodity.name }}</span>
        <span v-else class="blueprint-slot__unmapped">
          {{ option.commodityKey }}
        </span>
      </span>
    </div>

    <div class="blueprint-slot__body">
      <div class="blueprint-slot__control">
        <div class="blueprint-slot__quality">
          <span class="blueprint-slot__quality-label">
            {{ t("labels.blueprint.quality") }}
          </span>
          <div class="blueprint-slot__track">
            <!-- The caption is the hit target, not the stem: a stem sits over
                 the range input and would swallow a drag. -->
            <button
              v-for="mark in marks"
              :key="`cap-${mark.grade}`"
              type="button"
              class="blueprint-slot__mark"
              :class="{
                'blueprint-slot__mark--active': mark.grade === quality,
              }"
              :style="{ left: mark.left }"
              @click="applyGrade(mark.grade)"
            >
              {{ mark.grade }}
            </button>
            <span
              v-for="mark in marks"
              :key="`stem-${mark.grade}`"
              class="blueprint-slot__stem"
              :class="{
                'blueprint-slot__stem--active': mark.grade === quality,
              }"
              :style="{ left: mark.left }"
            />

            <input
              type="range"
              min="0"
              max="1000"
              step="1"
              :value="quality"
              :aria-label="t('labels.blueprint.quality')"
              @input="onQuality"
            />
          </div>
          <input
            type="number"
            min="0"
            max="1000"
            step="1"
            :value="quality"
            :aria-label="t('labels.blueprint.quality')"
            :class="{ 'blueprint-slot__number--below': belowGate }"
            @input="onQuality"
          />
        </div>

        <p v-if="belowGate" class="blueprint-slot__below">
          {{ t("labels.blueprint.belowGate", { quality: gate }) }}
        </p>

        <!-- Only ever shown to a reader who has the stock to match: the
             catalogue is public and most of its readers keep no inventory. -->
        <div
          v-if="held.own.length || held.fleet.length"
          class="blueprint-slot__held"
        >
          <div
            v-for="row in heldRows"
            :key="row.entry.id"
            class="blueprint-slot__held-row"
            :class="{
              'blueprint-slot__held-row--pick':
                row.entry.qualities.length === 1,
              'blueprint-slot__held-row--picked': isPicked(row.entry),
            }"
            @click="
              row.entry.qualities.length === 1 &&
              applyGrade(row.entry.qualities[0])
            "
          >
            <span class="blueprint-slot__held-dot" />

            <span class="blueprint-slot__held-grades">
              <button
                v-for="grade in row.entry.qualities"
                :key="grade"
                type="button"
                class="blueprint-slot__held-grade"
                :class="{
                  'blueprint-slot__held-grade--active': grade === quality,
                }"
                @click.stop="applyGrade(grade)"
              >
                {{ grade }}
              </button>
            </span>

            <span class="blueprint-slot__held-amount">
              {{ amountOf(row.entry) }}
            </span>

            <span class="blueprint-slot__held-where">
              <span class="blueprint-slot__held-preposition">
                {{ prepositionOf(row.entry) }}
              </span>
              <router-link
                v-if="placeRoute(row.entry)"
                :to="placeRoute(row.entry)!"
                class="blueprint-slot__held-place"
                @click.stop
              >
                {{ placeOf(row.entry) }}
              </router-link>
              <span v-else class="blueprint-slot__held-place">
                {{ placeOf(row.entry) }}
              </span>
            </span>

            <span v-if="row.tag" class="blueprint-slot__held-tag">
              {{ row.tag }}
            </span>
          </div>
        </div>
      </div>

      <div v-if="ramps.length" class="blueprint-slot__stats">
        <div v-for="ramp in ramps" :key="ramp.key" class="blueprint-slot__stat">
          <div class="blueprint-slot__stat-head">
            <span class="blueprint-slot__stat-name">{{ ramp.name }}</span>

            <!-- The result, which is the question being asked. Where the
               catalogue holds no figure for the stat this is the factor
               itself, so the row always leads with its own answer. -->
            <span
              v-if="ramp.plotted"
              class="blueprint-slot__result"
              :class="{ 'blueprint-slot__result--muted': belowGate }"
            >
              {{ ramp.headline }}
            </span>

            <!-- 598 modifiers name a stat and carry no figures at all.
               Rendering the nils would print 0 → 0 and invent a number. -->
            <span v-else class="blueprint-slot__stat-unvalued">
              {{ t("labels.blueprint.unvalued") }}
            </span>
          </div>

          <template v-if="ramp.plotted">
            <!-- The plot itself stays uncoloured: it is the shape of the ramp,
               which is the same shape whichever way the stat improves. The
               figure beside it carries the judgement. -->
            <div class="blueprint-slot__plot">
              <svg
                class="blueprint-slot__spark"
                viewBox="0 0 100 38"
                preserveAspectRatio="none"
                aria-hidden="true"
              >
                <line
                  x1="0"
                  y1="36"
                  x2="100"
                  y2="36"
                  class="blueprint-slot__axis"
                  vector-effect="non-scaling-stroke"
                />
                <polyline
                  :points="ramp.points"
                  class="blueprint-slot__line"
                  vector-effect="non-scaling-stroke"
                />
              </svg>

              <!-- The grade the catalogue's own figure describes, so the
                   reader can see which side of standard they are buying. -->
              <span
                class="blueprint-slot__neutral"
                :style="{ left: ramp.neutralLeft }"
              />

              <!-- Over the plot, not in it: the plot is stretched to the row,
                   and a circle drawn inside would be stretched with it. -->
              <span
                class="blueprint-slot__marker"
                :class="{ 'blueprint-slot__marker--muted': belowGate }"
                :style="{ left: ramp.markerLeft, top: ramp.markerTop }"
              />
            </div>

            <div class="blueprint-slot__stat-foot">
              <span v-if="ramp.base" class="blueprint-slot__stat-base">
                {{ t("labels.blueprint.atNeutral", { value: ramp.base }) }}
              </span>
              <span
                class="blueprint-slot__delta"
                :class="`blueprint-slot__delta--${ramp.trend}`"
              >
                {{ ramp.delta }}
              </span>
              <span class="blueprint-slot__stat-span">{{ ramp.span }}</span>
              <span class="blueprint-slot__stat-domain">{{ ramp.domain }}</span>
              <!-- Where the stat has no base the headline already is the
                 factor, and printing it twice said nothing twice. -->
              <span v-if="ramp.showFactor" class="blueprint-slot__stat-factor">
                {{ ramp.factor }}
              </span>
            </div>
          </template>
        </div>
      </div>

      <p v-else class="blueprint-slot__no-stats">
        {{ t("labels.blueprint.noStats") }}
      </p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
