<template>
  <div ref="compareTopView">
    <div class="row compare-row compare-section">
      <div class="col-12 compare-row-label sticky-left">
        <div
          :class="{
            active: visible,
          }"
          class="text-right metrics-title"
          @click="toggle"
        >
          {{ t("labels.metrics.topView") }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-12 compare-row-item"
      />
    </div>

    <Collapsed id="topView" :visible="visible" class="row">
      <div class="col-12">
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          />
          <div
            v-for="model in models"
            :key="`${model.slug}-top-view`"
            class="col-6 text-center compare-row-item compare-row-item-top-view"
          >
            <FleetchartItemImage
              :label="model.name"
              :src="model.media.sideView?.small"
              :width="length(model)"
              max-width="100%"
            />
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          />
          <div
            v-for="model in models"
            :key="`${model.slug}-top-view`"
            class="col-6 text-center compare-row-item compare-row-item-top-view"
          >
            <FleetchartItemImage
              :label="model.name"
              :src="model.media.topView?.small"
              :width="length(model)"
              max-width="100%"
            />
          </div>
        </div>
      </div>
    </Collapsed>
  </div>
</template>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import FleetchartItemImage from "@/frontend/components/Fleetchart/List/Item/Image/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const visible = ref(false);

const compareTopView = ref<HTMLElement | null>(null);
const maxWidth = computed(() => {
  if (!compareTopView.value) {
    return 0;
  }

  return compareTopView.value.offsetWidth / 4;
});

const scale = computed(() => {
  if (props.models.length <= 0) {
    return 0;
  }

  const maxLength = Math.max(
    ...props.models.map((model) => model.fleetchartLength),
    0,
  );

  return maxWidth.value / (maxLength * 3);
});

const length = (model: Model) => model.fleetchartLength * 3 * scale.value;

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

<script lang="ts">
export default {
  name: "ModelsCompareTopView",
};
</script>
