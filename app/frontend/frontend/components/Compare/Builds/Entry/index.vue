<script lang="ts">
export default {
  name: "CompareBuildsEntry",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import MissionText from "@/frontend/components/MissionText/index.vue";
import {
  FIELD_UNITS,
  entryRoute,
  fieldKey,
  movement,
  readableField,
  slotPosition,
} from "@/frontend/components/Compare/Builds/format";
import {
  ScDataDiffCatalogueEnum,
  ScDataDiffKindEnum,
  type ScDataDiffEntry,
  type ScDataDiffField,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  entry: ScDataDiffEntry;
  catalogue: ScDataDiffCatalogueEnum;
  /** Shows this fact alone, for a list that is already about it. */
  field?: string;
};

const props = withDefaults(defineProps<Props>(), {
  field: undefined,
});

const { t, tExists, toNumber } = useI18n();

const to = computed(() => entryRoute(props.catalogue, props.entry.slug));

const fields = computed(() =>
  props.field
    ? props.entry.fields.filter((item) => item.field === props.field)
    : props.entry.fields,
);

const label = ({ field, category }: ScDataDiffField) => {
  const slot = `labels.hardpoint.categories.${category}`;
  if (category && tExists(slot)) {
    const position = slotPosition(field, (word) =>
      t(`labels.buildDiff.positions.${word}`),
    );

    return [t(slot), position].filter(Boolean).join(" · ");
  }

  const key = `labels.buildDiff.fields.${fieldKey(field)}`;
  if (tExists(key)) return t(key);

  return readableField(field);
};

const isRatio = (field: string) =>
  field.includes(".resistances.") || field.endsWith("_ratio");

const number = (field: string, raw: number, digits?: number) => {
  // `toNumber` reads zero as "not available".
  if (raw === 0) return "0";
  if (isRatio(field)) return `${(raw * 100).toFixed(digits ?? 0)}%`;
  // It also rounds, and states a mass in tonnes, which hides small values.
  if (digits !== undefined || Math.abs(raw) < 1) {
    const exact = String(Number(raw.toFixed(digits ?? 6)));

    return fieldKey(field) === "volume" ? `${exact} SCU` : exact;
  }
  if (fieldKey(field) === "mass") return `${toNumber(raw)} kg`;

  return String(toNumber(raw, FIELD_UNITS[fieldKey(field)] || ""));
};

const value = (
  field: string,
  raw: ScDataDiffField["from"],
  digits?: number,
) => {
  if (raw === null || raw === undefined || raw === "") {
    return t("labels.buildDiff.absent");
  }
  if (typeof raw === "boolean") {
    return t(raw ? "labels.buildDiff.yes" : "labels.buildDiff.no");
  }

  return typeof raw === "string" ? raw : number(field, raw, digits);
};

// Both sides, precise enough to tell apart.
const values = (item: ScDataDiffField) => {
  const plain = [value(item.field, item.from), value(item.field, item.to)];
  if (plain[0] !== plain[1]) return plain;

  return [value(item.field, item.from, 4), value(item.field, item.to, 4)];
};

const pill = computed(() =>
  props.entry.kind === ScDataDiffKindEnum.added
    ? PillVariantsEnum.SUCCESS
    : PillVariantsEnum.DANGER,
);
</script>

<template>
  <div class="build-diff-entry" data-test="build-diff-entry">
    <div class="build-diff-entry__head">
      <component
        :is="to ? 'router-link' : 'span'"
        :to="to"
        class="build-diff-entry__name"
      >
        <MissionText v-if="catalogue === 'missions'" :text="entry.name" />
        <template v-else>{{ entry.name }}</template>
      </component>
      <span v-if="entry.context" class="build-diff-entry__context">
        {{ entry.context }}
      </span>
      <Pill
        class="build-diff-entry__kind"
        v-if="entry.kind !== ScDataDiffKindEnum.changed"
        :variant="pill"
      >
        {{ t(`labels.buildDiff.kinds.${entry.kind}`) }}
      </Pill>
    </div>

    <dl v-if="fields.length" class="build-diff-entry__facts">
      <div
        v-for="item in fields"
        :key="item.field"
        class="build-diff-entry__fact"
        data-test="build-diff-fact"
      >
        <dt>{{ label(item) }}</dt>
        <dd>
          <span class="build-diff-entry__old">
            {{ values(item)[0] }}
          </span>
          <i class="fa-light fa-arrow-right" aria-hidden="true" />
          <span class="sr-only">{{ t("labels.buildDiff.becomes") }}</span>
          <span class="build-diff-entry__new">
            {{ values(item)[1] }}
          </span>
          <span class="build-diff-entry__delta">{{ movement(item) }}</span>
        </dd>
      </div>
    </dl>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
