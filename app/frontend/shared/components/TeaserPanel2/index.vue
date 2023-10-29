<template>
  <Panel alignment="left" :slim="slim">
    <PanelImage
      :image="storeImage"
      image-size="auto"
      rounded="left"
      alt="Odyssey"
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

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
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

type Props = {
  item: Model | ModelModule | ModelUpgrade;
  to?: RouteLocationRaw;
  level?: "h2" | "h3" | "h4";
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  level: "h2",
  slim: false,
});

const { supported: webpSupported } = useWebpCheck();

const mobile = useMobile();

const storeImage = computed(() => {
  if (mobile.value && props.item.media.storeImage?.medium) {
    return props.item.media.storeImage?.medium;
  }

  if (props.item.media.storeImage?.large) {
    return props.item.media.storeImage?.large;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<script lang="ts">
export default {
  name: "",
};
</script>
