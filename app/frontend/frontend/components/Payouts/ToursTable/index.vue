<script lang="ts">
export default {
  name: "PayoutsToursTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { Tour } from "@/services/fyApi";

type Props = {
  tours: Tour[];
  loading?: boolean;
  // A fleet's own list already knows whose tours it is showing; the standalone
  // list mixes fleet tours in with ad-hoc ones, and there the column is the
  // only thing telling them apart.
  withFleet?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  withFleet: false,
});

const emit = defineEmits<{
  (event: "row-click", tour: Tour): void;
}>();

const { t, l } = useI18n();

const columns = computed<BaseTableCol<Tour>[]>(() => {
  const cols: BaseTableCol<Tour>[] = [
    { name: "title", label: t("labels.payouts.title"), flexGrow: 2 },
  ];

  if (props.withFleet) {
    cols.push({ name: "fleet", label: t("labels.fleet.index") });
  }

  cols.push(
    { name: "startsAt", label: t("labels.payouts.startsAt") },
    { name: "status", label: t("labels.status"), width: "120px" },
  );

  return cols;
});
</script>

<template>
  <BaseTable
    :records="tours"
    primary-key="id"
    :columns="columns"
    :loading="loading"
    :empty-visible="!tours.length && !loading"
    row-clickable
    @row-click="(tour: Tour) => emit('row-click', tour)"
  >
    <template #col-fleet="{ record }">
      <span v-if="record.fleet">{{ record.fleet.name }}</span>
    </template>
    <template #col-startsAt="{ record }">
      <span v-if="record.startsAt">{{
        l(record.startsAt, "datetime.formats.dateTime")
      }}</span>
    </template>
    <template #col-status="{ record }">
      <Pill>
        {{
          t(
            `labels.payouts.${record.status === "settled" ? "settled" : "open"}`,
          )
        }}
      </Pill>
    </template>
    <template #empty>
      <slot name="empty">{{ t("empty.payouts.tours") }}</slot>
    </template>
  </BaseTable>
</template>
