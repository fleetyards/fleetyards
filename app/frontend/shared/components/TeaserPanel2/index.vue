<script lang="ts">
export default {
  name: "TeaserPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelImage from "@/shared/components/base/Panel/Image/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { useMobile } from "@/shared/composables/useMobile";
import {
  type Model,
  type ModelModule,
  type ModelUpgrade,
} from "@/services/fyApi";
import { type RouteLocationRaw } from "vue-router";
import { PanelAlignmentsEnum } from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

type Props = {
  item: Model | ModelModule | ModelUpgrade;
  to?: RouteLocationRaw;
  level?: HeadingLevelEnum;
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  level: HeadingLevelEnum.H2,
  slim: false,
});

const { supported: webpSupported } = useWebpCheck();

const mobile = useMobile();

const storeImage = computed(() => {
  if (mobile.value && props.item.media.storeImage?.mediumUrl) {
    return props.item.media.storeImage?.mediumUrl;
  }

  if (props.item.media.storeImage?.largeUrl) {
    return props.item.media.storeImage?.largeUrl;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<template>
  <Panel :alignment="PanelAlignmentsEnum.LEFT" :slim="slim">
    <PanelImage
      :image="storeImage"
      image-size="auto"
      rounded="left"
      :alt="item.name"
      :to="to"
    />
    <div>
      <PanelHeading :level="level">
        <template v-if="to">
          <router-link :to="to">{{ item.name }}</router-link>
        </template>
        <template v-else>{{ item.name }} </template>
      </PanelHeading>
      <PanelBody no-min-height no-padding-top>
        {{ item.description }}
      </PanelBody>
    </div>
  </Panel>
</template>
