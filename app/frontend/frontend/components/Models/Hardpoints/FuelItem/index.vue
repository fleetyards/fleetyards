<script lang="ts">
export default {
  name: "HardpointFuelItem",
};
</script>

<script lang="ts" setup>
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointSize from "@/frontend/components/Models/Hardpoints/Size/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import {
  HardpointSourceEnum,
  HardpointCategoryEnum,
  type Hardpoint,
  type FuelTank,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  hardpoints: Hardpoint[];
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const hardpoint = computed(() => {
  return props.hardpoints[0];
});

const count = computed(() => {
  return props.hardpoints.length;
});

const typeData = computed(() => {
  return hardpoint.value.component?.typeData as FuelTank;
});

const label = computed(() => {
  if (hardpoint.value.component?.subType === "Fuel") {
    return t("labels.hardpoint.fuelTanks.hydrogen");
  }
  if (hardpoint.value.component?.subType === "QuantumFuel") {
    return t("labels.hardpoint.fuelTanks.quantum");
  }

  return "TBD";
});
</script>

<template>
  <HardpointItem :count="count">
    <template #default>
      <HardpointSize :size="hardpoint.maxSize" />
      <HardpointComponent>
        <template v-if="hardpoint.source === HardpointSourceEnum.game_files">
          {{ label }}
          <span>
            {{ toNumber(typeData.capacity, "cargo") }}
          </span>
        </template>
        <template v-else>
          {{ hardpoint.name }}
          <span v-if="hardpoint.details">
            {{ hardpoint.details }}
          </span>
        </template>
      </HardpointComponent>
    </template>
  </HardpointItem>
</template>
