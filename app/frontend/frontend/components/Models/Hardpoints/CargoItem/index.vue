<script lang="ts">
export default {
  name: "HardpointCargoItem",
};
</script>

<script lang="ts" setup>
import { type ComponentCargoGrid, type Hardpoint } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  hardpoints: Hardpoint[];
  intended?: boolean;
};

withDefaults(defineProps<Props>(), {
  intended: false,
});

const { t, toNumber } = useI18n();

const typeData = (hardpoint: Hardpoint) => {
  return hardpoint.component?.typeData as ComponentCargoGrid;
};

const label = (hardpoint: Hardpoint) => {
  const parts = hardpoint.name.split("_");

  return parts
    ?.filter((part) => {
      return !["cargo-hardpoint", "cargogrid", "hardpoint", "cargo"].includes(
        part,
      );
    })
    .join(" ");
};
</script>

<template>
  <div
    v-for="hardpoint in hardpoints"
    :key="hardpoint.id"
    class="hardpoint-item"
  >
    <div class="hardpoint-item__wrapper">
      <div
        class="hardpoint-item__inner"
        :class="{ 'has-component': hardpoint.component }"
      >
        <div class="hardpoint-item__cargo-container text-muted">
          {{ t("labels.hardpoint.maxContainerSize") }}:
          {{
            toNumber(
              typeData(hardpoint).dimensions.maxContainerSize.size || "",
              "cargo",
            )
          }}
        </div>
        <div class="hardpoint-item__cargo">
          {{ toNumber(typeData(hardpoint).dimensions.scu || "", "cargo") }}
        </div>
        <div class="hardpoint-item__component">
          <template v-if="hardpoint.component">
            {{ label(hardpoint) }}
          </template>
          <template v-else>TBD</template>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
