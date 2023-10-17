<template>
  <Panel
    :id="id || celestialObject.slug"
    class="celestial-object-panel"
    :bg-image="image"
    :to="detailRoute"
    :link-label="celestialObject.name"
    :outer-spacing="outerSpacing"
  >
    <PanelHeading level="h3" :size="slim ? undefined : 'large'" shadow="top">
      <router-link :to="detailRoute" :aria-label="celestialObject.name">
        {{ celestialObject.name }}
      </router-link>
    </PanelHeading>
    <PanelBody
      v-if="withMoons && moons?.items.length"
      class="celestial-object-panel-body"
    >
      <h3 class="sr-only">
        {{ t("headlines.moons") }}
      </h3>
      <transition-group
        name="fade-list"
        class="celestial-object-panel-moons"
        tag="div"
        appear
      >
        <div
          v-for="moon in moons.items"
          :key="moon.slug"
          class="fade-list-item celestial-object-panel-moons-item"
        >
          <CelestialObjectPanel
            :celestial-object="moon"
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
import type { CelestialObject } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useI18n } from "@/frontend/composables/useI18n";
import { useQuery } from "@tanstack/vue-query";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

type Props = {
  celestialObject: CelestialObject;
  withMoons?: boolean;
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

const { celestialObjects: celestialObjectsService } = useApiClient();

const { data: moons } = useQuery({
  queryKey: ["moons", props.celestialObject.slug],
  queryFn: () =>
    celestialObjectsService.list({
      q: {
        parentEq: props.celestialObject.slug,
      },
    }),
  enabled: props.withMoons,
});

const detailRoute = computed(() => {
  return {
    name: "celestial-object",
    params: {
      starsystem: props.celestialObject.starsystem.slug,
      slug: props.celestialObject.slug,
    },
  };
});

const { supported: webpSupported } = useWebpCheck();

const image = computed(() => {
  if (props.celestialObject.media.storeImage) {
    if (props.large) {
      return props.celestialObject.media.storeImage.large;
    }

    return props.celestialObject.media.storeImage.medium;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<script lang="ts">
export default {
  name: "CelestialObjectPanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
