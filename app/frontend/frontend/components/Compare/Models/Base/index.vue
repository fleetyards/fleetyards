<script lang="ts">
export default {
  name: "ModelsCompareBase",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import ModelsRow from "@/frontend/components/Compare/Models/Row/index.vue";
import ModelsRowTitle from "@/frontend/components/Compare/Models/Row/Title/index.vue";
import ModelsRowLabel from "@/frontend/components/Compare/Models/Row/Label/index.vue";
import ModelsRowValue from "@/frontend/components/Compare/Models/Row/Value/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  slim: false,
});

const { t, toDollar, toNumber, toUEC } = useI18n();

const visible = ref(false);

onMounted(() => {
  visible.value = props.models.length > 0;
});

watch(
  () => props.models,
  () => {
    visible.value = props.models.length > 0;
  },
);

const toggle = () => {
  visible.value = !visible.value;
};

const rows = [
  {
    key: "base-manufacturer",
    label: t("model.manufacturer"),
    value: (model: Model) => model.manufacturer?.name,
  },
  {
    key: "base-production-status",
    label: t("model.productionStatus"),
    value: (model: Model) =>
      t(`labels.model.productionStatus.${model.productionStatus}`),
  },
  {
    key: "base-focus",
    label: t("model.focus"),
    value: (model: Model) => model.focus,
  },
  {
    key: "base-classification",
    label: t("model.classification"),
    value: (model: Model) => model.classificationLabel,
  },
  {
    key: "base-size",
    label: t("model.size"),
    value: (model: Model) => model.metrics.sizeLabel,
  },
  {
    key: "base-length",
    label: t("model.length"),
    value: (model: Model) => toNumber(model.metrics.length, "distance"),
  },
  {
    key: "base-beam",
    label: t("model.beam"),
    value: (model: Model) => toNumber(model.metrics.beam, "distance"),
  },
  {
    key: "base-height",
    label: t("model.height"),
    value: (model: Model) => toNumber(model.metrics.height, "distance"),
  },
  {
    key: "base-mass",
    label: t("model.mass"),
    value: (model: Model) => toNumber(model.metrics.mass, "weight"),
  },
  {
    key: "base-cargo",
    label: t("model.cargo"),
    value: (model: Model) => toNumber(model.metrics.cargo, "cargo"),
  },
  {
    key: "base-price",
    label: t("model.price"),
    value: (model: Model) => toUEC(model.price),
  },
  {
    key: "base-pledge-price",
    label: t("model.pledgePrice"),
    value: (model: Model) => toDollar(model.pledgePrice),
  },
];
</script>

<template>
  <ModelsRow :models="models" row-key="base" :slim="slim" sticky-left section>
    <template #label>
      <ModelsRowTitle
        :active="visible"
        :title="t('labels.metrics.base')"
        @click="toggle"
      />
    </template>
  </ModelsRow>
  <Collapsed id="base" :visible="visible" class="row">
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
          <ModelsRowLabel>
            {{ row.label }}
          </ModelsRowLabel>
        </template>
        <template #default="{ model }">
          <ModelsRowValue>
            <!-- eslint-disable-next-line vue/no-v-html -->
            <span v-html="row.value(model)" />
          </ModelsRowValue>
        </template>
      </ModelsRow>
    </div>
  </Collapsed>
</template>
