<script lang="ts">
export default {
  name: "HangarImportDetails",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import LoadingLine from "@/shared/components/LoadingLine/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import { useImport, type ImportDetails } from "@/services/fyApi";

type Props = {
  importId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

// Fetched on its own: the list payload deliberately omits `details`, and a run
// can name a couple of hundred ships.
const { data, isLoading } = useImport(computed(() => props.importId));

const DETAIL_SECTIONS = [
  "imported",
  "found",
  "movedToWanted",
  "deleted",
  "grouped",
  "unchanged",
  "missing",
  "missingComponents",
  "missingUpgrades",
] as const;

const sections = computed(() => {
  const details = data.value?.details as ImportDetails | undefined;

  if (!details) return [];

  return DETAIL_SECTIONS.flatMap((key) => {
    const names = details[key];

    return names?.length ? [{ key, names }] : [];
  });
});
</script>

<template>
  <div class="import-details">
    <LoadingLine :loading="isLoading" />
    <RowsSkeleton v-if="isLoading" :count="2" :meta="false" />

    <p v-if="!isLoading && !sections.length" class="import-details__empty">
      {{ t("labels.imports.noDetails") }}
    </p>

    <div
      v-for="section in sections"
      :key="section.key"
      class="import-details__section"
    >
      <h4 class="import-details__title">
        {{ t(`labels.imports.details.${section.key}`) }}
        <span class="import-details__count">{{ section.names.length }}</span>
      </h4>
      <ul class="import-details__list">
        <li v-for="name in section.names" :key="`${section.key}-${name}`">
          {{ name }}
        </li>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.import-details {
  position: relative;
}

.import-details__section + .import-details__section {
  margin-top: 0.75rem;
}

.import-details__title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0 0 0.25rem;
  font-size: 0.8125rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--text-muted);
}

.import-details__count {
  font-variant-numeric: tabular-nums;
}

.import-details__list {
  margin: 0;
  padding-left: 1.25rem;
  columns: 2;

  @media (max-width: 767px) {
    columns: 1;
  }
}

.import-details__empty {
  margin: 0;
  color: var(--text-muted);
}
</style>
