<script lang="ts">
export default {
  name: "CompareShipsPage",
};
</script>

<script lang="ts" setup>
import CompareLayout from "@/frontend/components/Compare/Layout/index.vue";
import CompareForm from "@/frontend/components/Compare/Models/Form/index.vue";
import CompareActions from "@/frontend/components/Compare/Models/Actions/index.vue";
import { useModelSections } from "@/frontend/components/Compare/sections/model";
import { useLoadoutSections } from "@/frontend/components/Compare/sections/loadout";
import type {
  CompareColumn,
  CompareSection,
} from "@/frontend/components/Compare/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { useCompareHardpoints } from "@/frontend/composables/useCompareHardpoints";
import { useCompareModels } from "@/frontend/composables/useCompareModels";

const { t } = useI18n();

const { filter, filters } = useCompareModelFilters();

const items = computed(() => filters.value.models);

// One detail request per ship rather than the models index. Compare wants more
// of a ship than any list does, and taking it from the index means every list
// carries those fields for rows nobody compares.
//
// No watcher here: the composable tracks the compare set itself and fetches only
// what it has not seen, so adding a fourth ship leaves the three on screen alone.
const {
  models,
  loading: modelsLoading,
  asyncStatus,
} = useCompareModels(() => items.value);

const { hardpointsFor, loading: hardpointsLoading } = useCompareHardpoints(
  () => models.value,
);

const { views, base, crew, flight, cargo, fuel } = useModelSections(
  () => models.value,
  hardpointsFor,
);

const { combat, defense, hull, salvage, mining, systems, utility } =
  useLoadoutSections(() => models.value, hardpointsFor);

// Combat-forward, then what keeps you alive, then what you carry — the ship page's
// emphasis. Sections that no compared ship has data for drop out on their own.
const sections = computed<CompareSection[]>(() =>
  [
    views.value,
    base.value,
    crew.value,
    flight.value,
    combat.value,
    defense.value,
    hull.value,
    salvage.value,
    mining.value,
    cargo.value,
    fuel.value,
    systems.value,
    utility.value,
  ].filter((section): section is CompareSection => !!section),
);

const columns = computed<CompareColumn[]>(() =>
  models.value.map((model) => ({
    key: model.slug,
    name: model.name,
    subtitle: model.manufacturer?.name,
    image: model.media.storeImage,
    to: { name: "ship", params: { slug: model.slug } },
  })),
);

const remove = (slug: string) => {
  filter({ models: items.value.filter((entry) => entry !== slug) });
};
</script>

<template>
  <Heading hidden>{{ t("headlines.compare.ships") }}</Heading>

  <CompareLayout
    :columns="columns"
    :sections="sections"
    :async-status="asyncStatus"
    :loading="hardpointsLoading || (modelsLoading && !!models.length)"
    :empty-title="t('headlines.compare.ships')"
    :empty-info="t('texts.compare.ships.info')"
    :count-label="t('labels.compare.shipCount', { count: models.length })"
    :remove-label="t('labels.compare.removeModel')"
    @remove="remove"
  >
    <template #header>
      <CompareForm />
      <CompareActions :models="models" />
    </template>
  </CompareLayout>
</template>
