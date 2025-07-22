<script lang="ts">
export default {
  name: "ModelsCompareView",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import ModelsRow from "@/frontend/components/Compare/Models/Row/index.vue";
import RowTitle from "@/frontend/components/Compare/Models/Row/Title/index.vue";
import FleetchartItemImage from "@/frontend/components/Fleetchart/List/Item/Image/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  slim: false,
});

const { t } = useI18n();

const visible = ref(false);

const maxLength = computed(() => {
  return Math.max(
    ...props.models.map((model) => model.metrics.fleetchartLength || 1),
    0,
  );
});

const shipLength = (model: Model) => {
  return model.metrics.fleetchartLength || 1;
};

const length = (model: Model) => {
  return (shipLength(model) * 100) / maxLength.value;
};

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
</script>

<template>
  <ModelsRow
    :models="models"
    row-key="top-view-placeholder"
    :slim="slim"
    sticky-left
    section
  >
    <template #label>
      <RowTitle
        :active="visible"
        :title="t('labels.metrics.views')"
        @click="toggle"
      />
    </template>
  </ModelsRow>

  <Collapsed id="topView" :visible="visible" class="row">
    <div class="col-12">
      <ModelsRow
        :models="models"
        row-key="side-view"
        :slim="slim"
        sticky-left
        centered
      >
        <template #default="{ model }">
          <FleetchartItemImage
            v-if="model.media.sideView?.smallUrl"
            :label="model.name"
            :src="model.media.sideView?.smallUrl"
            :max-width="`${length(model)}%`"
          />
        </template>
      </ModelsRow>
      <ModelsRow
        :models="models"
        row-key="top-view"
        :slim="slim"
        sticky-left
        centered
      >
        <template #default="{ model }">
          <FleetchartItemImage
            v-if="model.media.topView?.smallUrl"
            :label="model.name"
            :src="model.media.topView?.smallUrl"
            :max-width="`${length(model)}%`"
          />
        </template>
      </ModelsRow>
    </div>
  </Collapsed>
</template>
