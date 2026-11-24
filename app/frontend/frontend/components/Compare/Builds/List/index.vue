<script lang="ts">
export default {
  name: "CompareBuildsList",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import Entry from "@/frontend/components/Compare/Builds/Entry/index.vue";
import FieldGroup from "@/frontend/components/Compare/Builds/FieldGroup/index.vue";
import {
  ScDataDiffCatalogueEnum,
  ScDataDiffKindEnum,
  useScDataDiff,
} from "@/services/fyApi";
import { useFieldLabel } from "@/frontend/components/Compare/Builds/useFieldLabel";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";

// Keyed on the catalogue and the builds by its parent, so one catalogue's
// records are never drawn as another's while the next are on their way.
type Props = {
  catalogue: ScDataDiffCatalogueEnum;
  from: string;
  to: string;
  kind: ScDataDiffKindEnum;
  field?: string;
  search?: string;
};

const props = withDefaults(defineProps<Props>(), {
  field: undefined,
  search: undefined,
});

const emit = defineEmits<{
  showField: [field: string];
}>();

const { t } = useI18n();

const fieldLabel = useFieldLabel();

const { page, perPage, updatePerPage } = usePagination();

const { data: diff, ...asyncStatus } = useScDataDiff(
  () => props.catalogue,
  () => ({
    from: props.from,
    to: props.to,
    kind: props.kind,
    field: props.field,
    search: props.search,
    page: page.value,
    perPage: perPage.value,
  }),
);

// A list this long is read by what changed rather than by name. A ship's slots
// are named per ship, so loadouts have no facts to group by.
const GROUP_FROM = 24;

const grouped = computed(
  () =>
    props.kind === ScDataDiffKindEnum.changed &&
    !props.field &&
    !props.search &&
    props.catalogue !== ScDataDiffCatalogueEnum.loadouts &&
    (diff.value?.counts.changed || 0) > GROUP_FROM,
);

// Only above the changes: the other lists state no facts to leave out.
const unrecorded = computed(() => {
  if (props.kind !== ScDataDiffKindEnum.changed || props.field) return "";

  const labels = (diff.value?.unrecorded || []).map((item) =>
    fieldLabel(item.field),
  );

  return [...new Set(labels)].join(", ");
});
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <Alert
        v-if="diff && !diff.recorded"
        :variant="AlertVariantsEnum.INFO"
        data-test="build-diff-not-recorded"
      >
        {{ t("labels.buildDiff.notRecorded") }}
      </Alert>

      <div v-else-if="diff" class="build-diff-list">
        <Alert
          v-if="unrecorded"
          :variant="AlertVariantsEnum.INFO"
          data-test="build-diff-unrecorded"
        >
          {{
            t("labels.buildDiff.unrecorded", {
              fields: unrecorded,
            })
          }}
        </Alert>

        <template v-if="grouped">
          <FieldGroup
            v-for="(item, index) in diff.fields"
            :key="item.field"
            :catalogue="catalogue"
            :from="from"
            :to="to"
            :field="item.field"
            :count="item.count"
            :initially-open="index === 0"
            @show-all="emit('showField', $event)"
          />
        </template>

        <template v-else>
          <p v-if="!diff.items.length" data-test="build-diff-empty">
            {{ t("labels.buildDiff.nothing") }}
          </p>
          <Entry
            v-for="entry in diff.items"
            :key="entry.id"
            :entry="entry"
            :catalogue="catalogue"
            :field="field"
          />
          <Paginator
            :query-result-ref="diff"
            :per-page="perPage"
            :update-per-page="updatePerPage"
          />
        </template>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.build-diff-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
</style>
