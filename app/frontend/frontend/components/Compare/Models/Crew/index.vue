<template>
  <div>
    <div class="row compare-row compare-section">
      <div class="col-12 compare-row-label sticky-left">
        <div
          :class="{
            active: visible,
          }"
          class="text-right metrics-title"
          @click="toggle"
        >
          {{ t("labels.metrics.crew") }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-12 compare-row-item"
      />
    </div>

    <Collapsed id="crew" :visible="visible" class="row">
      <div class="col-12">
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.minCrew") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-min-crew`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.minCrew, "people") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.maxCrew") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-min-crew`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.maxCrew, "people") }}
            </span>
          </div>
        </div>
      </div>
    </Collapsed>
  </div>
</template>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

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
</script>

<script lang="ts">
export default {
  name: "ModelsCompareCrew",
};
</script>
