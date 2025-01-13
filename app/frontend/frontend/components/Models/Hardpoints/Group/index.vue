<script lang="ts">
export default {
  name: "HardpointGroup",
};
</script>

<script lang="ts" setup>
import { groupBy, sortBy } from "@/shared/utils/Array";
import Panel from "@/shared/components/Panel/index.vue";
import {
  type Model,
  type ModelModule,
  type Hardpoint,
  type HardpointGroupEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import HardpointCategory from "@/frontend/components/Models/Hardpoints/Category/index.vue";
import { HardpointCategoryEnum } from "@/services/fyAdminApi";

type Props = {
  group: HardpointGroupEnum;
  hardpoints: Hardpoint[];
  withoutTitle?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withoutTitle: false,
});

const { t } = useI18n();

const groupByCategory = (items: Hardpoint[]) => {
  return groupBy<Hardpoint>(sortBy<Hardpoint>(items, "category"), "category");
};

const categories = computed(() => {
  const items = groupByCategory(props.hardpoints);

  const availableCategories: { [key in HardpointCategoryEnum]?: Hardpoint[] } =
    {};

  Object.keys(items).forEach((category) => {
    if (
      [
        HardpointCategoryEnum.CONTROLLER,
        HardpointCategoryEnum.UNKNOWN,
      ].includes(category as HardpointCategoryEnum)
    ) {
      return;
    }

    availableCategories[category as HardpointCategoryEnum] = items[category];
  });

  return availableCategories;
});
</script>

<template>
  <div
    v-if="hardpoints.length && Object.values(categories).length"
    class="hardpoint-group"
  >
    <h2 v-if="!withoutTitle" class="hardpoint-group-label">
      {{ t(`labels.hardpoint.groups.${group.toLowerCase()}`) }}
    </h2>
    <Panel slim>
      <div class="hardpoint-group__inner">
        <HardpointCategory
          v-for="(items, category) in categories"
          :key="category"
          :hardpoints="items || []"
          :category="category"
        />
      </div>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
