<script lang="ts">
export default {
  name: "HardpointThrusterItem",
};
</script>

<script lang="ts" setup>
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointSize from "@/frontend/components/Models/Hardpoints/Size/index.vue";
import HardpointManufacturer from "@/frontend/components/Models/Hardpoints/Manufacturer/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import {
  HardpointSourceEnum,
  type Hardpoint,
  type ComponentThruster,
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

const typeData = computed(() => {
  return hardpoint.value.component?.typeData as ComponentThruster;
});

const count = computed(() => {
  return props.hardpoints.length;
});
</script>

<template>
  <HardpointItem :count="count">
    <template #default>
      <HardpointSize :size="hardpoint.maxSize" />
      <HardpointComponent>
        <template v-if="hardpoint.source === HardpointSourceEnum.GAME_FILES">
          <template v-if="hardpoint.component">
            {{
              t(
                `labels.hardpoint.thrusters.subTypes.${hardpoint.component.subType || "FixedThruster"}`,
              )
            }}
            <span>
              {{ toNumber(typeData.thrustCapacity, "newton") }}
              {{ t("labels.hardpoint.thrusters.thrust") }}
            </span>
          </template>
          <template v-else>
            <span>TBD</span>
          </template>
        </template>
        <template v-else>
          {{ hardpoint.name }}
          <span v-if="hardpoint.details">
            {{ hardpoint.details }}
          </span>
        </template>
      </HardpointComponent>
      <HardpointManufacturer
        :manufacturer="hardpoint.component?.manufacturer"
      />
    </template>
  </HardpointItem>
</template>
