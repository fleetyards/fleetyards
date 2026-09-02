<script lang="ts">
export default {
  name: "StatsCsvExportBtn",
};
</script>

<script lang="ts" setup>
import { computed } from "vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useStatsCsv,
  useStatsCsvReady,
  type StatsChart,
  type StatsMetric,
} from "@/shared/composables/useStatsCsv";

type Props = {
  /** Names the subject in the filename: "stats", "<slug>-fleet", ... */
  scope: string;
  /** One chart's data, for the button in that chart's panel heading. */
  chart?: StatsChart;
  /** Every chart on the page, for the page-level button. */
  charts?: StatsChart[];
  /** The page's quick-stat panels, for the page-level button. */
  metrics?: StatsMetric[];
  withLabel?: boolean;
  variant?: `${BtnVariantsEnum}`;
  size?: `${BtnSizesEnum}`;
};

const props = withDefaults(defineProps<Props>(), {
  chart: undefined,
  charts: undefined,
  metrics: undefined,
  withLabel: false,
  variant: undefined,
  size: undefined,
});

const { t } = useI18n();

const { exportChart, exportAll } = useStatsCsv(() => props.scope);

const label = computed(() =>
  props.chart ? t("actions.exportCsv") : t("actions.exportAllCsv"),
);

// A single `chart` is the panel-heading button; `charts` plus `metrics` is the
// one in the page header that writes the whole page as one file.
const charts = computed(() =>
  props.chart ? [props.chart] : props.charts || [],
);

const ready = useStatsCsvReady(charts, () => props.metrics || []);

const download = () => {
  if (props.chart) {
    exportChart(props.chart);
    return;
  }

  exportAll(props.metrics || [], props.charts || []);
};
</script>

<template>
  <Btn
    v-tooltip="withLabel ? undefined : label"
    :aria-label="label"
    :disabled="!ready"
    :variant="variant"
    :size="size"
    :data-test="chart ? `export-csv-${chart.name}` : 'export-csv-all'"
    @click="download"
  >
    <i class="fa-duotone fa-file-csv" />
    <span v-if="withLabel">{{ label }}</span>
  </Btn>
</template>
