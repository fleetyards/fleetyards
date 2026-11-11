<script lang="ts">
export default {
  name: "HomeDashboardShipTile",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { type MediaFile } from "@/services/fyApi";

type Props = {
  name: string;
  to: RouteLocationRaw;
  image?: MediaFile;
  sub?: string;
  tag?: string;
};

const props = withDefaults(defineProps<Props>(), {
  image: undefined,
  sub: undefined,
  tag: undefined,
});

const { supported: webpSupported } = useWebpCheck();

const imageUrl = computed(
  () =>
    props.image?.mediumUrl ||
    props.image?.largeUrl ||
    (webpSupported.value ? fallbackImage : fallbackImageJpg),
);
</script>

<template>
  <router-link :to="to" class="home-ship-tile">
    <Panel :bg-image="imageUrl" :outer-spacing="false">
      <PanelHeading
        :shadow="PanelHeadingShadowEnum.TOP"
        :level="HeadingLevelEnum.H3"
      >
        {{ name }}
        <span v-if="sub" class="home-ship-tile__sub">{{ sub }}</span>
        <template v-if="tag" #actions>
          <Pill uppercase data-test="home-ship-tile-tag">{{ tag }}</Pill>
        </template>
      </PanelHeading>
    </Panel>
  </router-link>
</template>

<style lang="scss" scoped>
.home-ship-tile {
  --panel-image-height: 120px;

  display: block;
  min-width: 0;
  text-decoration: none;
}

.home-ship-tile__sub {
  display: block;
  overflow: hidden;
  color: var(--color-text-dim, #959595);
  font-family: "Open Sans", sans-serif;
  font-size: 0.75rem;
  font-weight: 400;
  letter-spacing: normal;
  text-overflow: ellipsis;
  text-transform: none;
  white-space: nowrap;
}
</style>
