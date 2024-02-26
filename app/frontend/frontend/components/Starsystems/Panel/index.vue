<template>
  <Panel
    :id="id || starsystem.slug"
    class="starsystem-panel"
    :bg-image="image"
    :to="detailRoute"
    :link-label="starsystem.name"
    :outer-spacing="outerSpacing"
  >
    <PanelHeading level="h3" :size="slim ? undefined : 'large'" shadow="top">
      <router-link :to="detailRoute" :aria-label="starsystem.name">
        {{ starsystem.name }}
      </router-link>
    </PanelHeading>
    <PanelBody
      v-if="withCelestialObjects && celestialObjects?.items.length"
      class="starsystem-panel-body"
    >
      <h3 class="sr-only">
        {{ t("headlines.celestialObjects") }}
      </h3>
      <transition-group
        name="fade-list"
        class="starsystem-panel-celestial-objects"
        tag="div"
        appear
      >
        <div
          v-for="celestialObject in celestialObjects.items"
          :key="celestialObject.slug"
          class="fade-list-item starsystem-panel-celestial-objects-item"
        >
          <CelestialObjectPanel
            :celestial-object="celestialObject"
            :outer-spacing="false"
            slim
          />
        </div>
      </transition-group>
    </PanelBody>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import CelestialObjectPanel from "@/frontend/components/CelestialObjects/Panel/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import type { Starsystem } from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

type Props = {
  starsystem: Starsystem;
  withCelestialObjects?: boolean;
  id?: string;
  slim?: boolean;
  outerSpacing?: boolean;
  large?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withMoons: false,
  id: undefined,
  slim: false,
  outerSpacing: true,
  large: false,
});

const { t } = useI18n();

const detailRoute = computed(() => {
  return { name: "starsystem", params: { slug: props.starsystem.slug } };
});

const { celestialObjects: celestialObjectsService } = useApiClient();

const { data: celestialObjects } = useQuery({
  queryKey: ["celestialObjects", props.starsystem.slug],
  queryFn: () =>
    celestialObjectsService.list({
      q: {
        parentIdNull: true,
        starsystemEq: props.starsystem.slug,
      },
    }),
});

const { supported: webpSupported } = useWebpCheck();

const image = computed(() => {
  if (props.starsystem.media.storeImage) {
    if (props.large) {
      return props.starsystem.media.storeImage.large;
    }

    return props.starsystem.media.storeImage.medium;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<script lang="ts">
export default {
  name: "StarsystemPanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
