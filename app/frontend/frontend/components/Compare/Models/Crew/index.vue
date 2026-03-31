<script lang="ts">
export default {
  name: "ModelsCompareCrew",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import CompareModelsRow from "@/frontend/components/Compare/Models/Row/index.vue";
import CompareModelsRowTitle from "@/frontend/components/Compare/Models/Row/Title/index.vue";
import CompareModelsRowLabel from "@/frontend/components/Compare/Models/Row/Label/index.vue";
import CompareModelsRowValue from "@/frontend/components/Compare/Models/Row/Value/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { Model } from "@/services/fyApi";

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
    key: "crew-min-crew",
    label: t("model.minCrew"),
    value: (model: Model) => toNumber(model.crew.min, "people"),
  },
  {
    key: "crew-max-crew",
    label: t("model.maxCrew"),
    value: (model: Model) => toNumber(model.crew.max, "people"),
  },
];
</script>

<template>
  <div>
    <CompareModelsRow
      :models="models"
      row-key="crew"
      :slim="slim"
      sticky-left
      section
    >
      <template #label>
        <CompareModelsRowTitle
          :active="visible"
          :title="t('labels.metrics.crew')"
          @click="toggle"
        />
      </template>
    </CompareModelsRow>

    <Collapsed id="crew" :visible="visible" class="row">
      <div class="col-12">
        <CompareModelsRow
          v-for="row in rows"
          :key="row.key"
          :models="models"
          :row-key="row.key"
          :slim="slim"
          sticky-left
        >
          <template #label>
            <CompareModelsRowLabel>
              {{ row.label }}
            </CompareModelsRowLabel>
          </template>
          <template #default="{ model }">
            <CompareModelsRowValue>
              <!-- eslint-disable-next-line vue/no-v-html -->
              <span v-html="row.value(model)" />
            </CompareModelsRowValue>
          </template>
        </CompareModelsRow>
      </div>
    </Collapsed>
  </div>
</template>
