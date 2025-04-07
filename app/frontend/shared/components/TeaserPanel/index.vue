<script lang="ts">
export default {
  name: "TeaserPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelImage from "@/shared/components/base/Panel/Image/index.vue";
import type { MediaImage } from "@/services/fyApi";
import type { RouteLocationNamedRaw } from "vue-router";
import { PanelAlignmentsEnum } from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

type TeaserItem = {
  name: string;
  title?: string;
  label?: string;
  description?: string;
  media?: {
    storeImage?: MediaImage;
  };
};

type Props = {
  item: TeaserItem;
  to?: RouteLocationNamedRaw;
  withDescription?: boolean;
  fullscreen?: boolean;
  variant?: "default" | "text";
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  withDescription: true,
  fullscreen: false,
  variant: "default",
  slim: false,
});

const image = computed(() => {
  return props.item.media?.storeImage?.medium;
});

const title = computed(() => {
  if (props.item.title) {
    return props.item.title;
  }
  if (props.item.label) {
    return props.item.label;
  }
  return props.item.name;
});
</script>

<template>
  <Panel :alignment="PanelAlignmentsEnum.LEFT" :slim="slim">
    <PanelImage
      :image="image"
      image-size="auto"
      rounded="left"
      :alt="item.name"
    />
    <div>
      <PanelHeading :level="HeadingLevelEnum.H2">
        <router-link v-if="to" :to="to">
          {{ title }}
        </router-link>
        <template v-else>
          {{ title }}
        </template>
      </PanelHeading>
      <PanelBody no-min-height no-padding-top>
        <div v-if="!fullscreen" class="teaser-panel-body teaser-panel-item">
          <p v-if="withDescription">
            {{ item.description }}
          </p>
        </div>
      </PanelBody>
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
