<template>
  <div class="row metrics-padding">
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.metrics.speed") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div v-if="isGroundVehicle" class="row">
        <div class="col-6">
          <div class="metrics-label">{{ t("model.groundMaxSpeed") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.speeds.groundMaxSpeed, "speed") }}
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ t("model.groundReverseSpeed") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.speeds.groundReverseSpeed, "speed") }}
          </div>
        </div>
      </div>
      <div v-else class="row">
        <div class="col-6">
          <div class="metrics-label">{{ t("model.scmSpeed") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.speeds.scmSpeed, "speed") }}
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ t("model.maxSpeed") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.speeds.maxSpeed, "speed") }}
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <div class="seperator" />
        </div>
      </div>
      <div v-if="isGroundVehicle" class="row">
        <div class="col-6">
          <div class="metrics-label">{{ t("model.groundAcceleration") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.speeds.groundAcceleration, "speed") }}
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ t("model.groundDecceleration") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.speeds.groundDecceleration, "speed") }}
          </div>
        </div>
      </div>
      <template v-else>
        <div class="row">
          <div class="col-6">
            <div class="metrics-label">
              {{ t("model.scmSpeedAcceleration") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.scmSpeedAcceleration, "seconds") }}
            </div>
          </div>
          <div class="col-6">
            <div class="metrics-label">
              {{ t("model.scmSpeedDecceleration") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.scmSpeedDecceleration, "seconds") }}
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-6">
            <div class="metrics-label">
              {{ t("model.maxSpeedAcceleration") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.maxSpeedAcceleration, "seconds") }}
            </div>
          </div>
          <div class="col-6">
            <div class="metrics-label">
              {{ t("model.maxSpeedDecceleration") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.maxSpeedDecceleration, "seconds") }}
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-6 col-lg-4">
            <div class="metrics-label">{{ t("model.pitch") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.pitch, "rotation") }}
            </div>
          </div>
          <div class="col-6 col-lg-4">
            <div class="metrics-label">{{ t("model.yaw") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.yaw, "rotation") }}
            </div>
          </div>
          <div class="col-6 col-lg-4">
            <div class="metrics-label">{{ t("model.roll") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.roll, "rotation") }}
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const isGroundVehicle = computed(() => props.model.metrics.isGroundVehicle);
</script>

<script lang="ts">
export default {
  name: "SpeedMetrics",
};
</script>
