<script lang="ts">
export default {
  name: "FleetContractsProgress",
};
</script>

<script lang="ts" setup>
import {
  type FleetContractProgress,
  type FleetContractProgressLine,
  FleetContractQualityMatchEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";

type Props = {
  progress: FleetContractProgress;
  // Only a transport contract has a collection leg, so only it shows what is
  // still sitting in somebody's hold.
  showPickup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showPickup: false,
});

const { t } = useI18n();

const percent = (fraction: number) => `${Math.round(fraction * 100)}%`;

// "at least 500" or "exactly 500" — the line decides which, and the reader has
// to see which, because an over-grade delivery counts for one and not the other.
const qualityLabel = (line: FleetContractProgressLine) =>
  t(
    line.qualityMatch === FleetContractQualityMatchEnum.EXACT
      ? "labels.fleets.contracts.exactQuality"
      : "labels.fleets.contracts.minQuality",
    { value: line.quality as number },
  );

const quantity = (value: string) => {
  const parsed = Number(value);

  return Number.isFinite(parsed) ? String(parsed) : value;
};

const unitLabel = (line: FleetContractProgressLine) =>
  t(`labels.logistics.units.${line.unit}`);

// How much of the line is out of the source and not yet at the destination.
// Drawn *behind* the delivered fill, so the two read as one bar: goods in a
// courier's hold are on their way, not a second measure.
const pickedWidth = (line: FleetContractProgressLine) => {
  const requested = Number(line.requested);
  if (!Number.isFinite(requested) || requested <= 0) return "0%";

  const inHold = Number(line.pickedUp) + Number(line.delivered);

  return `${Math.min(100, Math.round((inHold / requested) * 100))}%`;
};
</script>

<template>
  <div class="contract-progress" data-test="contract-progress">
    <div class="contract-progress__overall">
      <div class="contract-progress__overall-bar">
        <div
          class="contract-progress__overall-fill"
          :style="{ width: percent(props.progress.fraction) }"
        />
      </div>
      <span class="contract-progress__overall-value">
        {{ percent(props.progress.fraction) }}
      </span>
    </div>

    <div
      v-for="line in props.progress.lines"
      :key="line.itemId"
      class="contract-progress__line"
      data-test="contract-progress-line"
    >
      <div class="contract-progress__head">
        <router-link
          v-if="catalogueItemRoute(line.item)"
          :to="catalogueItemRoute(line.item)!"
          class="contract-progress__name"
        >
          {{ line.name }}
        </router-link>
        <span v-else class="contract-progress__name">{{ line.name }}</span>
        <span
          v-if="line.quality != null"
          class="contract-progress__quality"
          data-test="contract-progress-quality"
        >
          {{ qualityLabel(line) }}
        </span>
        <span class="contract-progress__counts">
          {{ quantity(line.delivered) }} / {{ quantity(line.requested) }}
          {{ unitLabel(line) }}
        </span>
      </div>

      <div class="contract-progress__bar">
        <div
          v-if="props.showPickup"
          class="contract-progress__picked"
          :style="{ width: pickedWidth(line) }"
        />
        <div
          class="contract-progress__fill"
          :class="{ 'contract-progress__fill--complete': line.complete }"
          :style="{ width: percent(line.fraction) }"
        />
      </div>

      <p v-if="props.showPickup" class="contract-progress__pickup">
        {{
          t("labels.fleets.contracts.pickedUp", {
            quantity: quantity(line.pickedUp),
          })
        }}
      </p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
