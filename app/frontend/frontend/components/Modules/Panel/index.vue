<script lang="ts">
export default {
  name: "ModulePanel",
};
</script>

<script lang="ts" setup>
import { groupBy, sortBy } from "@/shared/utils/Array";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import HardpointCategory from "@/frontend/components/Models/Hardpoints/Category/index.vue";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { type ModelModule } from "@/services/fyApi";
import {
  PanelShadowsEnum,
  PanelBgRoundedEnum,
} from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";

type Props = {
  module: ModelModule;
};

const props = defineProps<Props>();

const { supported: webpSupported } = useWebpCheck();

const storeImage = computed(() => {
  if (props.module.media.storeImage?.mediumUrl) {
    return props.module.media.storeImage.mediumUrl;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});

const hardpoints = computed(() => {
  return props.module.hardpoints || [];
});

const groupByCategory = (items: Hardpoint[]) => {
  return groupBy<Hardpoint>(sortBy<Hardpoint>(items, "category"), "category");
};

const categories = computed(() => {
  const items = groupByCategory(hardpoints.value);

  const availableCategories: { [key in HardpointCategoryEnum]?: Hardpoint[] } =
    {};

  Object.keys(items).forEach((category) => {
    if (
      (
        [
          HardpointCategoryEnum.CONTROLLER,
          HardpointCategoryEnum.UNKNOWN,
        ] as HardpointCategoryEnum[]
      ).includes(category as HardpointCategoryEnum)
    ) {
      return;
    }

    availableCategories[category as HardpointCategoryEnum] = items[category];
  });

  return availableCategories;
});

const hasFooter = computed(
  () => !!props.module.description || Object.keys(categories.value).length > 0,
);
</script>

<template>
  <Panel
    class="module-panel"
    :bg-image="storeImage"
    :bg-rounded="hasFooter ? PanelBgRoundedEnum.TOP : PanelBgRoundedEnum.ALL"
    :shadow="PanelShadowsEnum.TOP"
  >
    <template #default>
      <PanelHeading :level="HeadingLevelEnum.H2">
        {{ module.name }}
      </PanelHeading>
    </template>
    <template v-if="hasFooter" #footer>
      <PanelBody class="module-panel-body" no-min-height>
        <p v-if="module.description">
          {{ module.description }}
        </p>
        <HardpointCategory
          v-for="(items, category) in categories"
          :key="category"
          :hardpoints="items || []"
          :category="category"
        />
      </PanelBody>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
.module-panel {
  .module-panel-body {
    flex: 1;
  }
}
</style>
