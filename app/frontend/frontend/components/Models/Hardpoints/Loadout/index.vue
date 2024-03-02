<template>
  <div v-if="loadout" class="hardpoint-item-loadout">
    <div class="hardpoint-item-loadout-quantity">
      <img
        :src="loadoutListIcon"
        class="hardpoint-item-loadout-quantity-icon"
        alt="hardpoint-list-icon"
      />
      {{ loadoutsCount }}
      <span class="text-muted">x</span>
    </div>
    <div
      class="hardpoint-item-inner"
      :class="{ 'has-component': loadout.component }"
    >
      <div v-if="showComponent" class="hardpoint-item-size">
        {{ t("labels.hardpoint.size") }} {{ loadout.component?.size }}
      </div>
      <div class="hardpoint-item-component">
        <template v-if="showComponent">
          {{ loadout.component?.name }}
        </template>
        <template v-else>TBD</template>
      </div>
      <div
        v-if="loadout && loadout.component && loadout.component.manufacturer"
        class="hardpoint-item-component-manufacturer"
        v-html="loadout.component.manufacturer.name"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import loadoutListIcon from "@/images/icons/loadout-list-icon.svg";
import type { ModelHardpoint } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  hardpoint: ModelHardpoint;
};

const props = defineProps<Props>();

const { t } = useI18n();

const showComponent = computed(() => {
  return loadout.value?.component;
});

const loadoutsCount = computed(() => {
  return props.hardpoint.loadouts?.length;
});

const loadout = computed(() => {
  if (!props.hardpoint.loadouts?.length) {
    return undefined;
  }

  return props.hardpoint.loadouts[0];
});
</script>

<script lang="ts">
export default {
  name: "HardpointsLoadout",
};
</script>
