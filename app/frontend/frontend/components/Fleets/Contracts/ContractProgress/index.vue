<script lang="ts">
export default {
  name: "FleetContractsProgress",
};
</script>

<script lang="ts" setup>
import ProgressBar from "@/shared/components/ProgressBar/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  type FleetContractProgress,
  type FleetContractProgressLine,
  FleetContractQualityMatchEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

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

const percent = (fraction: number) => Math.round(fraction * 100);

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
</script>

<template>
  <div class="contract-progress" data-test="contract-progress">
    <ProgressBar
      :progress="percent(props.progress.fraction)"
      class="contract-progress__overall"
    />

    <div
      v-for="line in props.progress.lines"
      :key="line.itemId"
      class="contract-progress__line"
      data-test="contract-progress-line"
    >
      <Heading :level="HeadingLevelEnum.H4" class="contract-progress__name">
        {{ line.name }}
        <span v-if="line.quality != null" class="contract-progress__quality">
          {{ qualityLabel(line) }}
        </span>
      </Heading>

      <ProgressBar
        :progress="percent(line.fraction)"
        :label="`${quantity(line.delivered)} / ${quantity(line.requested)} ${t(
          `labels.logistics.units.${line.unit}`,
        )}`"
      />

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
