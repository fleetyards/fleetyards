<script lang="ts">
export default {
  name: "HardpointBaseItem",
};
</script>

<script lang="ts" setup>
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import { type Hardpoint, type CargoHold } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  hardpoints: Hardpoint[];
  intended?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  intended: false,
});

const { t, toNumber } = useI18n();

const hardpoint = computed(() => {
  return props.hardpoints[0];
});

const typeData = computed(() => {
  return hardpoint.value.component?.typeData as CargoHold;
});

const count = computed(() => {
  return props.hardpoints.length;
});

const name = computed(() => {
  return (
    hardpoint.value.component?.name || hardpoint.value.component?.scKey || ""
  );
});

const label = computed(() => {
  return name.value
    .split("_")
    .join(" ")
    .replace("hardpoint", "")
    .replace("cargogrid", "")
    .replace("temp", "")
    .replace(/\b\w/g, (l) => l.toUpperCase());
});
</script>

<template>
  <HardpointItem :count="count" :intended="intended">
    <template #default>
      <div class="hardpoint-item__cargo-container text-muted">
        {{ t("labels.hardpoint.maxContainerSize") }}:
        {{ toNumber(typeData.maxContainerSize?.size || "", "cargo") }}
      </div>
      <div class="hardpoint-item__cargo">
        {{ toNumber(typeData.capacity || "", "cargo") }}
      </div>
      <HardpointComponent class="hardpoint-item__cargo-component">
        <template v-if="hardpoint.component">
          {{ label }}
        </template>
        <template v-else>TBD</template>
      </HardpointComponent>
    </template>
  </HardpointItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
