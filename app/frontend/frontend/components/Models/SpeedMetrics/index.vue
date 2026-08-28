<script lang="ts">
export default {
  name: "SpeedMetrics",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const isGroundVehicle = computed(() => props.model.metrics.isGroundVehicle);

// Null for a concept ship, and for a catalogue loaded before the export named a
// thruster's type -- in both cases there is nothing to say rather than a zero.
const hasAcceleration = computed(
  () =>
    !!props.model.speeds.mainAcceleration ||
    !!props.model.speeds.retroAcceleration,
);
</script>

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
        <!-- Ships had no acceleration figure until now: the four columns that
             claimed to hold one held seconds and had not been written since 2024.
             These come from the thrusters the loadout fits, so a ship the export
             has not described shows nothing rather than a zero. -->
        <div v-if="hasAcceleration" class="row">
          <div class="col-6 col-lg-3">
            <div class="metrics-label">{{ t("model.mainAcceleration") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.mainAcceleration, "acceleration") }}
            </div>
          </div>
          <div class="col-6 col-lg-3">
            <div class="metrics-label">{{ t("model.retroAcceleration") }}:</div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.retroAcceleration, "acceleration") }}
            </div>
          </div>
          <div class="col-6 col-lg-3">
            <div class="metrics-label">
              {{ t("model.scmSpeedAcceleration") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.secondsToScmSpeed, "seconds") }}
            </div>
          </div>
          <div class="col-6 col-lg-3">
            <div class="metrics-label">
              {{ t("model.scmSpeedDecceleration") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(model.speeds.secondsToStopFromScmSpeed, "seconds") }}
            </div>
          </div>
        </div>
        <div v-if="hasAcceleration" class="row">
          <div class="col-12">
            <div class="seperator" />
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
