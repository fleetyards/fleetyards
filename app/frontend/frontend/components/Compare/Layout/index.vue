<script lang="ts">
export default {
  name: "CompareLayout",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";
import Loader from "@/shared/components/Loader/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import CompareTable from "@/frontend/components/Compare/Table/index.vue";
import CompareTabs from "@/frontend/components/Compare/Tabs/index.vue";
import type {
  CompareColumn,
  CompareSection,
} from "@/frontend/components/Compare/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";

type Props = {
  columns: CompareColumn[];
  sections: CompareSection[];
  asyncStatus: AsyncStatus;
  loading?: boolean;
  emptyTitle: string;
  emptyInfo: string;
  countLabel: string;
  removeLabel: string;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
});

const emit = defineEmits<{
  remove: [slug: string];
}>();

const { t } = useI18n();

const differencesOnly = ref(false);
const deltaMode = ref(false);
const chosen = ref<string>();

// The reader's pick while it is still a column, the first column otherwise.
// Not whichever column arrived first: the items load one request each, so that
// made the default depend on which response won the race.
const baseline = computed({
  get: () =>
    props.columns.some((column) => column.key === chosen.value)
      ? chosen.value
      : props.columns[0]?.key,
  set: (key) => {
    chosen.value = key;
  },
});
</script>

<template>
  <div class="row compare-models">
    <div class="col-12">
      <div class="compare-header">
        <CompareTabs />
        <div class="compare-header__actions">
          <slot name="actions" />
        </div>
      </div>

      <slot name="notice" />

      <AsyncData :async-status="asyncStatus">
        <template #resolved>
          <Empty
            v-if="!columns.length"
            :variant="EmptyVariantsEnum.BOX"
            hide-actions
          >
            <template #title>
              {{ emptyTitle }}
            </template>
            <template #info>
              <p class="text-muted">
                {{ emptyInfo }}
              </p>
              <div class="compare-empty__add">
                <slot name="add" :compact="false" />
              </div>
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
                :columns="columns"
                :sections="sections"
                :count-label="countLabel"
                :remove-label="removeLabel"
                :delta="deltaMode"
                :differences-only="differencesOnly"
                @remove="emit('remove', $event)"
              >
                <template #corner>
                  <slot name="add" :compact="true" />
                </template>
              </CompareTable>
            </Panel>
          </template>
        </template>
      </AsyncData>

      <!-- An item the link names that no longer resolves leaves only the error,
           and without a way to pick again the reader is stuck on it. -->
      <div v-if="asyncStatus.isError.value" class="compare-empty__add">
        <slot name="add" :compact="false" />
      </div>

      <!-- The one piece of feedback an incremental fetch gets: the table it is
           filling in stays on screen, so the spinner cannot live in its place. -->
      <Loader :loading="loading" fixed />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
