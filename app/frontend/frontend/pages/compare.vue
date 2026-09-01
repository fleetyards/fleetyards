<script lang="ts">
export default {
  name: "ComparePage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import CompareForm from "@/frontend/components/Compare/Models/Form/index.vue";
import CompareActions from "@/frontend/components/Compare/Models/Actions/index.vue";
import CompareTable from "@/frontend/components/Compare/Models/Table/index.vue";
import { useModelSections } from "@/frontend/components/Compare/sections/model";
import { useLoadoutSections } from "@/frontend/components/Compare/sections/loadout";
import type { CompareSection } from "@/frontend/components/Compare/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
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

const { combat, defense, hull, loadout } = useLoadoutSections(
  () => models.value,
  hardpointsFor,
);

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
    cargo.value,
    fuel.value,
    loadout.value,
  ].filter((section): section is CompareSection => !!section),
);

const differencesOnly = ref(false);
const deltaMode = ref(false);
const baseline = ref<string>();

// The baseline is a column, so it cannot outlive the set it belongs to.
watch(models, () => {
  if (!baseline.value || !items.value.includes(baseline.value)) {
    baseline.value = models.value[0]?.slug;
  }
});

const remove = (slug: string) => {
  filter({ models: items.value.filter((entry) => entry !== slug) });
};
</script>

<template>
  <Heading hidden>{{ t("headlines.compare.ships") }}</Heading>

  <div class="row compare-models">
    <div class="col-12">
      <div class="compare-header">
        <CompareForm />
        <CompareActions :models="models" />
      </div>

      <AsyncData :async-status="asyncStatus">
        <template #resolved>
          <Empty
            v-if="!models.length"
            :variant="EmptyVariantsEnum.BOX"
            hide-actions
          >
            <template #title>
              {{ t("headlines.compare.ships") }}
            </template>
            <template #info>
              <p class="text-muted">
                {{ t("texts.compare.ships.info") }}
              </p>
            </template>
          </Empty>

          <template v-else>
            <div class="compare-toolbar">
              <div class="compare-toolbar__modes">
                <Btn
                  :active="differencesOnly"
                  :size="BtnSizesEnum.SM"
                  @click="differencesOnly = !differencesOnly"
                >
                  {{ t("labels.compare.differencesOnly") }}
                </Btn>
                <Btn
                  :active="deltaMode"
                  :size="BtnSizesEnum.SM"
                  @click="deltaMode = !deltaMode"
                >
                  {{ t("labels.compare.compareToBaseline") }}
                </Btn>
              </div>

              <!-- Only the keys in play: the bar and the row winner in normal mode, the
                   comparison hues once a baseline is chosen. -->
              <dl class="compare-legend">
                <template v-if="deltaMode">
                  <dt class="compare-legend__key compare-legend__key--better">
                    +%
                  </dt>
                  <dd>{{ t("labels.compare.legend.better") }}</dd>
                  <dt class="compare-legend__key compare-legend__key--worse">
                    −%
                  </dt>
                  <dd>{{ t("labels.compare.legend.worse") }}</dd>
                </template>
                <template v-else>
                  <dt class="compare-legend__key compare-legend__key--bar">
                    <span />
                  </dt>
                  <dd>{{ t("labels.compare.legend.share") }}</dd>
                </template>
                <dt class="compare-legend__key compare-legend__key--best">▲</dt>
                <dd>{{ t("labels.compare.legend.best") }}</dd>
                <dt class="compare-legend__key compare-legend__key--worst">
                  ▼
                </dt>
                <dd>{{ t("labels.compare.legend.worst") }}</dd>
              </dl>
            </div>

            <!-- The panel is the frame: border, radius, end-caps and shadow all come
                 from the redesigned surface, so the table carries none of its own. -->
            <Panel class="compare-panel">
              <CompareTable
                v-model:baseline="baseline"
                :models="models"
                :sections="sections"
                :delta="deltaMode"
                :differences-only="differencesOnly"
                @remove="remove"
              />
            </Panel>
          </template>
        </template>
      </AsyncData>

      <!-- The one piece of feedback an incremental fetch gets: the table it is
           filling in stays on screen, so the spinner cannot live in its place. -->
      <Loader
        :loading="hardpointsLoading || (modelsLoading && !!models.length)"
        fixed
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "compare.scss";
</style>
