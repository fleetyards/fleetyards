<script lang="ts">
export default {
  name: "FleetContractsProgress",
};
</script>

<script lang="ts" setup>
import ProgressBar from "@/shared/components/ProgressBar/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { type FleetContractProgress } from "@/services/fyApi";
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
        <span v-if="line.minQuality" class="contract-progress__quality">
          {{
            t("labels.fleets.contracts.minQuality", { value: line.minQuality })
          }}
        </span>
      </Heading>

      <ProgressBar
        :progress="percent(line.fraction)"
        :label="`${quantity(line.delivered)} / ${quantity(line.requested)} ${t(
          `labels.fleets.contracts.unit.${line.unit}`,
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
