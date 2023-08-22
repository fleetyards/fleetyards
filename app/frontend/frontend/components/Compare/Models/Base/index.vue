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
          {{ t("labels.metrics.base") }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-12 compare-row-item"
      />
    </div>
    <Collapsed id="base" :visible="visible" class="row">
      <div class="col-12">
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.manufacturer") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-manufacturer`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value" v-html="model.manufacturer.name" />
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.productionStatus") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-production-status`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ t(`labels.model.productionStatus.${model.productionStatus}`) }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.focus") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-focus`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ model.focus }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.classification") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-classification`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ model.classificationLabel }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.size") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-size`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ model.sizeLabel }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.length") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-length`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.length, "distance") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.beam") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-beam`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.beam, "distance") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.height") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-height`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.height, "distance") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.mass") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-mass`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.mass, "weight") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.cargo") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-cargo`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.cargo, "cargo") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.price") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-cargo`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value" v-html="toUEC(model.price)" />
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.pledgePrice") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-cargo`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toDollar(model.lastPledgePrice) }}
            </span>
          </div>
        </div>
      </div>
    </Collapsed>
  </div>
</template>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t, toNumber, toUEC, toDollar } = useI18n();

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
  name: "ModelsCompareBase",
};
</script>
