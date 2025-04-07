<script lang="ts">
export default {
  name: "ModulePanel",
};
</script>

<script lang="ts" setup>
import { groupBy, sortBy } from "@/shared/utils/Array";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelImage from "@/shared/components/base/Panel/Image/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import HardpointCategory from "@/frontend/components/Models/Hardpoints/Category/index.vue";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { useMobile } from "@/shared/composables/useMobile";
import { type ModelModule } from "@/services/fyApi";
import { PanelAlignmentsEnum } from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";

type Props = {
  module: ModelModule;
};

const props = defineProps<Props>();

const { supported: webpSupported } = useWebpCheck();

const mobile = useMobile();

const storeImage = computed(() => {
  if (mobile.value && props.module.media.storeImage?.medium) {
    return props.module.media.storeImage?.medium;
  }

  if (props.module.media.storeImage?.large) {
    return props.module.media.storeImage?.large;
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
      [
        HardpointCategoryEnum.controller,
        HardpointCategoryEnum.unknown,
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
  <Panel :alignment="PanelAlignmentsEnum.LEFT" slim>
    <PanelImage
      :image="storeImage"
      image-size="auto"
      rounded="left"
      :alt="module.name"
    />
    <div>
      <PanelHeading :level="HeadingLevelEnum.H2">
        {{ module.name }}
      </PanelHeading>
      <PanelBody no-min-height no-padding-top>
        {{ module.description }}
        <hr v-if="Object.values(categories).length" />
        <HardpointCategory
          v-for="(items, category) in categories"
          :key="category"
          :hardpoints="items || []"
          :category="category"
        />
      </PanelBody>
    </div>
  </Panel>
</template>
