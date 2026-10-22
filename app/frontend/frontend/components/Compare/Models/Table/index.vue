<script lang="ts">
export default {
  name: "CompareModelsTable",
};
</script>

<script lang="ts" setup>
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { ViewImageSizeEnum } from "@/shared/components/ViewImage/types";
import FleetchartItemImage from "@/frontend/components/Fleetchart/List/Item/Image/index.vue";
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import { markExtremes } from "@/frontend/components/Compare/highlights";
import {
  deltasAgainst,
  type CompareDelta,
} from "@/frontend/components/Compare/delta";
import {
  rowIsUniform,
  type CompareLine,
  type CompareLinePart,
  type CompareSection,
  type CompareTableRow,
} from "@/frontend/components/Compare/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
  sections: CompareSection[];
  baseline?: string;
  delta?: boolean;
  differencesOnly?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  baseline: undefined,
  delta: false,
  differencesOnly: false,
});

const emit = defineEmits<{
  remove: [slug: string];
  "update:baseline": [slug: string];
}>();

const { t, toNumber } = useI18n();

// The reused hardpoint item lists every stat it has, which is right on the ship page and
// noise in a cell repeated across eight columns. Two beside the gold headline is enough
// to tell components apart.
provide("hardpointStatLimit", 2);

const pane = ref<HTMLElement>();

// Breathing room between the pane's last row and the bottom of the screen, and the
// height below which filling the viewport stops being worth it.
const PANE_GUTTER = 24;
const PANE_MIN = 320;

// A share of the viewport cannot reach the bottom of it: the pane starts a couple of
// hundred pixels down the page, so `76vh` left that same gap unused at the bottom and
// the taller the screen the more it wasted. Measured instead, from the document top so
// that scrolling the page does not resize the table under the cursor.
const paneMax = ref<string>();

const measurePane = () => {
  if (!pane.value) {
    return;
  }

  const top = Math.round(
    pane.value.getBoundingClientRect().top + window.scrollY,
  );

  paneMax.value = `max(${PANE_MIN}px, calc(100dvh - ${top + PANE_GUTTER}px))`;
};

onMounted(() => {
  void nextTick(measurePane);

  window.addEventListener("resize", measurePane);
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", measurePane);
});

// Tall store art at rest, collapsing to name and manufacturer once scrolled: the
// silhouette is half of what identifies a column, but a permanently tall header would
// cost a third of the pane.
const pinned = ref(false);

const onScroll = () => {
  pinned.value = (pane.value?.scrollTop ?? 0) > 24;
};

const collapsed = ref(new Set<string>());

const toggle = (id: string) => {
  const next = new Set(collapsed.value);

  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }

  collapsed.value = next;
};

const rowsFor = (section: CompareSection) =>
  props.differencesOnly
    ? section.rows.filter((row) => !rowIsUniform(row))
    : section.rows;

const baselineIndex = computed(() =>
  props.models.findIndex((model) => model.slug === props.baseline),
);

type ValueRow = Extract<CompareTableRow, { kind: "value" }>;

const marksFor = (row: ValueRow) =>
  markExtremes(
    row.cells.map((cell) => cell.raw),
    row.direction,
  );

// Share of the row's highest value. Eight numbers in a row is past what the eye ranks
// unaided, so every comparable figure carries its rank as well as its value.
const sharesFor = (row: ValueRow) => {
  if (!row.direction) {
    return row.cells.map(() => undefined);
  }

  const values = row.cells
    .map((cell) => cell.raw)
    .filter((value): value is number => typeof value === "number");
  const max = Math.max(...values, 0);

  return row.cells.map((cell) =>
    typeof cell.raw === "number" && max > 0
      ? Math.max((cell.raw / max) * 100, 2)
      : undefined,
  );
};

const deltasFor = (row: ValueRow) =>
  deltasAgainst(
    row.cells.map((cell) => cell.raw),
    baselineIndex.value,
    row.direction,
    !!row.counts,
  );

// Baseline mode speaks in percentages and differences, so it applies to the rows a
// baseline can anchor. A textual row — manufacturer, classification, production status — has nothing
// to diff, and keeps showing its values rather than collapsing to a column of dashes.
const anchored = (row: ValueRow) => deltasFor(row).some((entry) => entry);

type LinesRow = Extract<CompareTableRow, { kind: "lines" }>;

// Against a baseline, a part the baseline column does not fit is what differs.
const differsFromBaseline = (
  row: LinesRow,
  index: number,
  line: CompareLine,
) => {
  if (baselineIndex.value < 0 || index === baselineIndex.value) {
    return false;
  }

  return !row.cells[baselineIndex.value]?.lines.some(
    (entry) => entry.key === line.key,
  );
};

// The row's best and worst part by the figure each leads with, as the value rows
// mark theirs. Parts of a kind lead with the same figure -- a gun its DPS, a
// shield its HP -- so they rank against each other; a row with a single figure
// marks nothing.
const lineMark = (row: LinesRow, line: CompareLine) => {
  if (typeof line.raw !== "number") {
    return undefined;
  }

  const values = row.cells.flatMap((cell) =>
    cell.lines
      .map((entry) => entry.raw)
      .filter((raw): raw is number => typeof raw === "number"),
  );

  if (new Set(values).size < 2) {
    return undefined;
  }

  if (line.raw === Math.max(...values)) {
    return "best";
  }

  return line.raw === Math.min(...values) ? "worst" : undefined;
};

// The catalogue card a part's name opens, as on the ship page: only for a part
// with a name, and so a slug, of its own.
const catalogueItem = (part: CompareLinePart) => {
  const component = part.hardpoint.component;

  return component?.slug && component.name
    ? {
        type: "Component",
        slug: component.slug,
        name: part.name,
        listed: component.catalogued,
      }
    : undefined;
};

const signed = (value: number) =>
  `${value > 0 ? "+" : ""}${toNumber(value, "")}`;

const deltaLabel = (row: ValueRow, delta?: CompareDelta) => {
  if (!delta) {
    return "";
  }

  if (delta.percent === undefined) {
    const label = signed(delta.difference);

    return row.counts?.unit ? `${label} ${row.counts.unit}` : label;
  }

  return `${signed(
    Math.abs(delta.percent) < 10
      ? Math.round(delta.percent * 10) / 10
      : Math.round(delta.percent),
  )}%`;
};
</script>

<template>
  <div
    ref="pane"
    class="compare-table"
    :class="{ 'compare-table--pinned': pinned }"
    :style="{ '--compare-pane-max': paneMax }"
    @scroll="onScroll"
  >
    <table>
      <thead>
        <tr>
          <th scope="col" class="compare-table__rail compare-table__corner">
            <span class="compare-table__count">
              {{ t("labels.compare.shipCount", { count: models.length }) }}
            </span>
          </th>
          <th v-for="model in models" :key="model.slug" scope="col">
            <div class="compare-table__ship">
              <div class="compare-table__art">
                <ViewImage
                  v-if="model.media.storeImage"
                  :image="model.media.storeImage"
                  :size="ViewImageSizeEnum.LARGE"
                  :alt="model.name"
                  class="compare-table__image"
                />
                <div class="compare-table__actions">
                  <button
                    v-tooltip="t('labels.compare.useAsBaseline')"
                    type="button"
                    class="compare-table__action"
                    :class="{
                      'compare-table__action--on': baseline === model.slug,
                    }"
                    :aria-pressed="baseline === model.slug"
                    :aria-label="t('labels.compare.useAsBaseline')"
                    @click="emit('update:baseline', model.slug)"
                  >
                    <i class="fa-light fa-crosshairs" />
                  </button>
                  <button
                    v-tooltip="t('labels.compare.removeModel')"
                    type="button"
                    class="compare-table__action"
                    :aria-label="t('labels.compare.removeModel')"
                    @click="emit('remove', model.slug)"
                  >
                    <i class="fa-light fa-times" />
                  </button>
                </div>
              </div>
              <div class="compare-table__name">
                <router-link
                  :to="{ name: 'ship', params: { slug: model.slug } }"
                >
                  {{ model.name }}
                </router-link>
                <span v-if="baseline === model.slug" class="compare-table__tag">
                  {{ t("labels.compare.baseline") }}
                </span>
              </div>
              <div class="compare-table__mfr">
                {{ model.manufacturer?.name }}
              </div>
            </div>
          </th>
        </tr>
      </thead>

      <tbody>
        <template v-for="section in sections" :key="section.id">
          <tr class="compare-table__band">
            <th scope="row" class="compare-table__rail">
              <button
                type="button"
                class="compare-table__band-title"
                :aria-expanded="!collapsed.has(section.id)"
                :aria-controls="`compare-section-${section.id}`"
                @click="toggle(section.id)"
              >
                <i class="fa fa-chevron-down" />
                <span>{{ section.title }}</span>
                <span class="compare-table__dot" />
              </button>
            </th>
            <td :colspan="models.length">
              <div class="compare-table__band-rule" />
            </td>
          </tr>

          <template v-if="!collapsed.has(section.id)">
            <template v-for="row in rowsFor(section)" :key="row.key">
              <tr v-if="row.kind === 'value'" class="compare-table__row">
                <th scope="row" class="compare-table__rail">{{ row.label }}</th>
                <td
                  v-for="(cell, index) in row.cells"
                  :key="cell.key"
                  :class="{
                    'compare-table__cell--best':
                      marksFor(row)[index] === 'best',
                    'compare-table__cell--worst':
                      marksFor(row)[index] === 'worst',
                  }"
                >
                  <template v-if="delta && anchored(row)">
                    <div
                      v-if="index === baselineIndex"
                      class="compare-table__delta compare-table__delta--base"
                    >
                      {{ t("labels.compare.baseline") }}
                    </div>
                    <div
                      v-else-if="deltasFor(row)[index]"
                      class="compare-table__delta"
                      :class="`compare-table__delta--${deltasFor(row)[index]?.tone}`"
                    >
                      {{ deltaLabel(row, deltasFor(row)[index]) }}
                    </div>
                    <div v-else class="compare-table__empty">—</div>
                  </template>
                  <template v-else-if="cell.value">
                    <div class="compare-table__value">
                      <!-- eslint-disable-next-line vue/no-v-html -->
                      <span v-if="row.html" v-html="cell.value" />
                      <span v-else>{{ cell.value }}</span>
                      <span v-if="row.unit" class="compare-table__unit">
                        {{ row.unit }}
                      </span>
                    </div>
                    <div
                      v-if="sharesFor(row)[index]"
                      class="compare-table__track"
                    >
                      <div
                        class="compare-table__track-fill"
                        :style="{ width: `${sharesFor(row)[index]}%` }"
                      />
                    </div>
                  </template>
                  <div v-else class="compare-table__empty">—</div>
                </td>
              </tr>

              <tr v-else-if="row.kind === 'chips'" class="compare-table__row">
                <th scope="row" class="compare-table__rail">{{ row.label }}</th>
                <td v-for="cell in row.cells" :key="cell.key">
                  <div v-if="cell.chips.length" class="compare-table__chips">
                    <span
                      v-for="chip in cell.chips"
                      :key="chip.key"
                      class="chip"
                      :data-type="chip.key"
                      :data-negative="chip.negative ? 'true' : undefined"
                    >
                      <span class="chip__label">{{ chip.label }}</span>
                      <span class="chip__value">{{ chip.value }}</span>
                    </span>
                  </div>
                  <div v-else class="compare-table__empty">—</div>
                </td>
              </tr>

              <tr
                v-else-if="row.kind === 'composition'"
                class="compare-table__row"
              >
                <th scope="row" class="compare-table__rail">
                  <div class="compare-table__legend">
                    <span class="compare-table__legend-title">
                      {{ row.label }}
                    </span>
                    <span
                      v-for="entry in row.legend"
                      :key="entry.key"
                      class="compare-table__legend-entry"
                    >
                      <span
                        class="compare-table__swatch"
                        :style="{ background: entry.color }"
                      />
                      {{ entry.label }}
                    </span>
                  </div>
                </th>
                <td v-for="cell in row.cells" :key="cell.key">
                  <div v-if="cell.segments.length" class="compare-table__comp">
                    <span
                      v-for="segment in cell.segments"
                      :key="segment.key"
                      v-tooltip="segment.label"
                      :style="{
                        width: `${(segment.value / cell.segments.reduce((sum, s) => sum + s.value, 0)) * 100}%`,
                        background: segment.color,
                      }"
                    />
                  </div>
                  <div v-else class="compare-table__empty">—</div>
                </td>
              </tr>

              <tr v-else-if="row.kind === 'view'" class="compare-table__row">
                <th scope="row" class="compare-table__rail">{{ row.label }}</th>
                <td v-for="cell in row.cells" :key="cell.key">
                  <div class="compare-table__view">
                    <FleetchartItemImage
                      v-if="cell.src"
                      :label="cell.alt"
                      :src="cell.src"
                      :max-width="`${cell.widthPercent}%`"
                    />
                    <span v-else class="compare-table__empty">—</span>
                  </div>
                </td>
              </tr>

              <tr
                v-else-if="row.kind === 'lines'"
                class="compare-table__row compare-table__row--top"
              >
                <th scope="row" class="compare-table__rail">{{ row.label }}</th>
                <td v-for="(cell, index) in row.cells" :key="cell.key">
                  <div v-if="cell.lines.length" class="compare-lines">
                    <div
                      v-for="line in cell.lines"
                      :key="line.key"
                      class="compare-line"
                      :class="{
                        'compare-line--differs': differsFromBaseline(
                          row,
                          index,
                          line,
                        ),
                      }"
                      data-test="compare-line"
                    >
                      <div class="compare-line__head">
                        <span class="compare-line__qty">
                          {{ line.quantity }}×
                        </span>
                        <span v-if="line.size" class="compare-line__size">
                          {{ line.size }}
                        </span>
                        <span class="compare-line__name">
                          <CatalogueItemPopover
                            v-if="catalogueItem(line)"
                            :item="catalogueItem(line)!"
                            :record="line.hardpoint.component!"
                          />
                          <template v-else>{{ line.name }}</template>
                        </span>
                        <span
                          v-if="line.figure"
                          class="compare-line__figure"
                          :class="
                            lineMark(row, line) &&
                            `compare-line__figure--${lineMark(row, line)}`
                          "
                        >
                          {{ line.figure.value }}
                          <span class="compare-line__unit">
                            {{ line.figure.unit }}
                          </span>
                        </span>
                      </div>
                      <div v-if="line.context" class="compare-line__note">
                        {{ line.context }}
                      </div>
                      <div
                        v-for="part in line.parts"
                        :key="part.key"
                        class="compare-line__part"
                      >
                        <span v-if="part.size" class="compare-line__size">
                          {{ part.size }}
                        </span>
                        <span class="compare-line__name">
                          <CatalogueItemPopover
                            v-if="catalogueItem(part)"
                            :item="catalogueItem(part)!"
                            :record="part.hardpoint.component!"
                          />
                          <template v-else>{{ part.name }}</template>
                        </span>
                        <span v-if="part.figure" class="compare-line__figure">
                          {{ part.figure.value }}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div v-else class="compare-table__empty">—</div>
                </td>
              </tr>
            </template>
          </template>
        </template>
      </tbody>
    </table>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
