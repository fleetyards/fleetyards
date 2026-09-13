<script lang="ts">
export default {
  name: "FleetContractsStatePill",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { FleetContractStateEnum } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  state: FleetContractStateEnum;
};

const props = defineProps<Props>();

const { t } = useI18n();

// A draft and a cancelled contract both ask nothing of the reader, so both are
// neutral; `open` is the one that wants somebody to act on it.
const variant = computed(() => {
  switch (props.state) {
    case FleetContractStateEnum.OPEN:
      return PillVariantsEnum.DEFAULT;
    case FleetContractStateEnum.IN_PROGRESS:
      return PillVariantsEnum.WARNING;
    case FleetContractStateEnum.FULFILLED:
      return PillVariantsEnum.SUCCESS;
    case FleetContractStateEnum.EXPIRED:
      return PillVariantsEnum.DANGER;
    default:
      return PillVariantsEnum.NEUTRAL;
  }
});
</script>

<template>
  <Pill :variant="variant">
    {{ t(`labels.fleets.contracts.state.${props.state}`) }}
  </Pill>
</template>
