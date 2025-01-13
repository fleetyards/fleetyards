<script lang="ts">
export default {
  name: "HardpointBaseItem",
};
</script>

<script lang="ts" setup>
import { groupBy } from "@/shared/utils/Array";
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointBaseItem from "@/frontend/components/Models/Hardpoints/BaseItem/index.vue";
import HardpointSize from "@/frontend/components/Models/Hardpoints/Size/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import HardpointManufacturer from "@/frontend/components/Models/Hardpoints/Manufacturer/index.vue";
import {
  HardpointSourceEnum,
  HardpointCategoryEnum,
  type Hardpoint,
} from "@/services/fyApi";
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

const groupedLoadout = computed(() => {
  return groupBy<Hardpoint>(loadout.value, "groupKey");
});

const hardpointNames = computed(() => {
  return props.hardpoints
    .map((hp) => {
      return hp.name
        .split("_")
        .join(" ")
        .replace("hardpoint", "")
        .replace(/\b\w/g, (l) => l.toUpperCase());
    })
    .join(", ");
});
</script>

<template>
  <HardpointItem :count="count" :intended="intended">
    <template #default>
      <HardpointSize :size="hardpoint.maxSize" />
      <HardpointComponent>
        <template v-if="hardpoint.source === HardpointSourceEnum.GAME_FILES">
          <template v-if="hardpoint.component && hardpoint.component.name">
            {{ hardpoint.component.name }}
            <span v-if="hardpoint.component.itemClass">
              {{ hardpoint.component.itemClassLabel }}
              {{ t("labels.component.grade") }}
              {{ hardpoint.component.gradeLabel }}
            </span>
          </template>
          <template v-else>
            {{ hardpointNames }}
            <span v-if="!loadout.length">TBD</span>
          </template>
        </template>
        <template v-else>
          <template
            v-if="
              (hardpoint.category !== HardpointCategoryEnum.TURRET &&
                hardpoint.category !== HardpointCategoryEnum.MISSILE_RACKS) ||
              intended
            "
          >
            {{ hardpoint.name }}
          </template>
          <span v-if="hardpoint.details">
            {{ hardpoint.details }}
          </span>
        </template>
      </HardpointComponent>
      <HardpointManufacturer
        :manufacturer="hardpoint.component?.manufacturer"
      />
    </template>
    <template #loadout>
      <div v-if="loadout.length" class="hardpoint-item__loadout">
        <HardpointBaseItem
          v-for="(items, key) in groupedLoadout"
          :key="key"
          :hardpoints="items"
          intended
        />
      </div>
    </template>
  </HardpointItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
