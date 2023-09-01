<template>
  <div>
    <div class="row compare-row compare-section">
      <div class="col-12 compare-row-label sticky-left">
        <div
          :class="{
            active: visible,
          }"
          class="text-right metrics-title"
          @click="toggle()"
        >
          {{ t("labels.metrics.speed") }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-12 compare-row-item"
      />
    </div>

    <Collapsed id="speed" :visible="visible" class="row">
      <div class="col-12">
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.scmSpeed") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-scm-speed`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.scmSpeed, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.maxSpeed") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-max-speed`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.maxSpeed, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.compare.groundMaxSpeed") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-ground-max-speed`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.groundMaxSpeed, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.compare.groundReverseSpeed") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-ground-reverse-speed`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.groundReverseSpeed, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.pitch") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-pitch`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.pitch, "rotation") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.yaw") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-yaw`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.yaw, "rotation") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.roll") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-roll`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.roll, "rotation") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.scmSpeedAcceleration") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-scm-speed-acceleration`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.scmSpeedAcceleration, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.scmSpeedDecceleration") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-scm-speed-decceleration`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.scmSpeedDecceleration, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.maxSpeedAcceleration") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-max-speed-acceleration`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.maxSpeedAcceleration, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.maxSpeedDecceleration") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-max-speed-decceleration`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.maxSpeedDecceleration, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.compare.groundAcceleration") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-ground-acceleration`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.groundAcceleration, "speed") }}
            </span>
          </div>
        </div>
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          >
            {{ t("model.compare.groundDecceleration") }}
          </div>
          <div
            v-for="model in models"
            :key="`${model.slug}-ground-decceleration`"
            class="col-6 text-center compare-row-item"
          >
            <span class="metrics-value">
              {{ toNumber(model.speeds.groundDecceleration, "speed") }}
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
  name: "ModelsCompareSpeed",
};
</script>
