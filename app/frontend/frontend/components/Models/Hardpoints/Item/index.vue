<script lang="ts">
export default {
  name: "HardpointItem",
};
</script>

<script lang="ts" setup>
import loadoutListIcon from "@/images/icons/loadout-list-icon.svg";
import HardpointQuantity from "@/frontend/components/Models/Hardpoints/Quantity/index.vue";
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import { type Hardpoint } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  hardpoints: Hardpoint[];
  intended?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  intended: false,
});

const { t } = useI18n();

const hardpoint = computed(() => {
  return props.hardpoints[0];
});

const count = computed(() => {
  return props.hardpoints.length;
});

const loadout = computed(() => {
  if (hardpoint.value.hardpoints?.length) {
    return hardpoint.value.hardpoints;
  }

  if (
    hardpoint.value.component?.hardpoints?.length &&
    hardpoint.value.component.hardpoints[0].component
  ) {
    return hardpoint.value.component.hardpoints;
  }

  return [];
});
</script>

<template>
  <div class="hardpoint-item">
    <div class="hardpoint-item__list">
      <img
        v-if="intended"
        :src="loadoutListIcon"
        class="hardpoint-item__list-icon"
        alt="hardpoint-list-icon"
      />
      <HardpointQuantity :quantity="count" tag="span" />
    </div>
    <div class="hardpoint-item__wrapper">
      <div
        class="hardpoint-item__inner"
        :class="{ 'has-component': hardpoint.component }"
      >
        <div class="hardpoint-item__size">
          {{ t("labels.hardpoint.size") }} {{ hardpoint.maxSize }}
        </div>
        <div class="hardpoint-item__component">
          <template v-if="hardpoint.component">
            {{ hardpoint.component.name }}
            <span v-if="hardpoint.component.itemClass">
              {{ hardpoint.component.itemClassLabel }}
              {{ t("labels.component.grade") }}
              {{ hardpoint.component.gradeLabel }}
            </span>
          </template>
          <template v-else>TBD</template>
        </div>
        <!-- eslint-disable vue/no-v-html -->
        <div
          v-if="hardpoint.component && hardpoint.component.manufacturer"
          class="hardpoint-item__component-manufacturer"
          v-html="hardpoint.component.manufacturer.name"
        />
        <!-- eslint-enable vue/no-v-html -->
      </div>
      <div v-if="loadout.length" class="hardpoint-item__loadout">
        <HardpointItem :hardpoints="loadout" intended />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
