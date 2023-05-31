<template>
  <div
    v-tooltip.left="tooltip"
    class="hardpoint-item-inner"
    :class="{ 'has-component': hardpoint.component }"
  >
    <div class="hardpoint-item-size">
      {{ t("labels.hardpoint.size") }} {{ hardpoint.sizeLabel }}
    </div>
    <div
      v-if="hardpoint.itemSlots > 1 || showComponent"
      class="hardpoint-item-component"
    >
      <span v-if="hardpoint.itemSlots > 1" class="hardpoint-item-quantity">
        {{ hardpoint.itemSlots }}x
      </span>
      <template v-if="showComponent">
        {{ hardpoint.component.name }}
      </template>
      <template v-else-if="hardpoint.itemSlots > 1">TBD</template>
    </div>
    <div
      v-if="hardpoint.categoryLabel && showCategory"
      class="hardpoint-item-component"
    >
      <span v-if="hardpoint.itemSlots > 1" class="hardpoint-item-quantity">
        {{ hardpoint.itemSlots }}x
      </span>

      <img
        v-if="isMissileTurret"
        v-tooltip="hardpoint.categoryLabel"
        :src="turretIcon"
        class="hardpoint-type-icon-small"
        alt="icon-turrets"
      />
      <span v-else>
        {{ hardpoint.categoryLabel }}
      </span>
    </div>
    <div
      v-if="hardpoint.component && hardpoint.component.manufacturer"
      class="hardpoint-item-component-manufacturer"
    >
      {{ hardpoint.component.manufacturer.name }}
    </div>
  </div>
</template>

<script lang="ts" setup>
import turretIcon from "@/images/hardpoints/turrets-dark.svg";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  hardpoint: TModelHardpoint;
};

const props = defineProps<Props>();

const { t } = useI18n();

const tooltip = computed(() => {
  if (
    !showCategory.value &&
    props.hardpoint.categoryLabel !== props.hardpoint?.component?.name
  ) {
    return props.hardpoint.categoryLabel;
  }

  return props.hardpoint.details;
});

const isMissileTurret = computed(() => {
  return props.hardpoint.category === "missile_turret";
});

const showCategory = computed(() => {
  return props.hardpoint.type !== "turrets";
});

const showComponent = computed(() => {
  return (
    props.hardpoint.component &&
    !["main_thrusters", "maneuvering_thrusters"].includes(props.hardpoint.type)
  );
});
</script>

<script lang="ts">
export default {
  name: "HardpointItem",
};
</script>
