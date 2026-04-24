<script lang="ts">
export default {
  name: "ModelsCompareCargo",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import ModelsRow from "@/frontend/components/Compare/Models/Row/index.vue";
import RowTitle from "@/frontend/components/Compare/Models/Row/Title/index.vue";
import RowLabel from "@/frontend/components/Compare/Models/Row/Label/index.vue";
import RowValue from "@/frontend/components/Compare/Models/Row/Value/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model, CargoHold } from "@/services/fyApi";
import {
  CONTAINER_DEFS,
  SCU_UNIT,
} from "@/frontend/components/CargoGridViewer/constants";

type Props = {
  models: Model[];
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  slim: false,
});

const { t, toNumber } = useI18n();

const visible = ref(false);

onMounted(() => {
  visible.value = props.models.some((m) => m.cargoHolds?.length);
});

watch(
  () => props.models,
  () => {
    visible.value = props.models.some((m) => m.cargoHolds?.length);
  },
);

const toggle = () => {
  visible.value = !visible.value;
};

function maxPerSize(holds: CargoHold[], containerSize: number): number {
  const def = CONTAINER_DEFS.find((d) => d.size === containerSize);
  if (!def) return 0;

  let total = 0;
  for (const hold of holds) {
    const maxSize = hold.maxContainerSize?.size || 32;
    if (def.size > maxSize) continue;

    const gridX = hold.dimensions.x / SCU_UNIT;
    const gridY = hold.dimensions.y / SCU_UNIT;
    const gridZ = hold.dimensions.z / SCU_UNIT;

    const orientations = [
      { cx: def.x, cy: def.y, cz: def.z },
      { cx: def.y, cy: def.x, cz: def.z },
    ];

    let best = 0;
    for (const o of orientations) {
      if (o.cx > gridX || o.cy > gridY || o.cz > gridZ) continue;
      const count =
        Math.floor(gridX / o.cx) *
        Math.floor(gridY / o.cy) *
        Math.floor(gridZ / o.cz);
      if (count > best) best = count;
    }

    total += best;
  }

  return total;
}

function maxContainerSize(model: Model): number {
  if (!model.cargoHolds?.length) return 0;
  return Math.max(
    ...model.cargoHolds.map((h) => h.maxContainerSize?.size || 0),
  );
}

const rows = [
  {
    key: "cargo-total",
    label: t("model.cargo"),
    value: (model: Model) => toNumber(model.metrics.cargo, "cargo"),
  },
  {
    key: "cargo-max-container",
    label: t("labels.cargoGridViewer.maxContainerSize"),
    value: (model: Model) => {
      const size = maxContainerSize(model);
      return size ? `${size} SCU` : "-";
    },
  },
  ...CONTAINER_DEFS.map((def) => ({
    key: `cargo-container-${def.size}`,
    label: `${def.size} SCU`,
    value: (model: Model) => {
      if (!model.cargoHolds?.length) return "-";
      const count = maxPerSize(model.cargoHolds, def.size);
      return count > 0 ? `${count}x` : "-";
    },
  })),
];
</script>

<template>
  <ModelsRow :models="models" row-key="cargo" :slim="slim" sticky-left section>
    <template #label>
      <RowTitle
        :active="visible"
        :title="t('labels.metrics.cargo')"
        @click="toggle"
      />
    </template>
  </ModelsRow>

  <Collapsed id="cargo" :visible="visible" class="row">
    <div class="col-12">
      <ModelsRow
        v-for="row in rows"
        :key="row.key"
        :models="models"
        :row-key="row.key"
        :slim="slim"
        sticky-left
      >
        <template #label>
          <RowLabel>
            {{ row.label }}
          </RowLabel>
        </template>
        <template #default="{ model }">
          <RowValue>
            <span>{{ row.value(model) }}</span>
          </RowValue>
        </template>
      </ModelsRow>
    </div>
  </Collapsed>
</template>
