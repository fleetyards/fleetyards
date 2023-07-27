<template>
  <Panel>
    <div v-if="fullscreen" class="panel-heading">
      <h2 class="panel-title">
        {{ title }}
      </h2>
    </div>
    <div
      class="teaser-panel"
      :class="{
        'teaser-panel-text': variant === 'text',
        'teaser-panel-fullscreen': fullscreen,
      }"
    >
      <div class="teaser-panel-image teaser-panel-item">
        <LazyImage :src="image" v-if="image" />
      </div>
      <div v-if="!fullscreen" class="teaser-panel-body teaser-panel-item">
        <router-link v-if="to" :to="to">
          <h3>{{ title }}</h3>
          <p v-if="withDescription">
            {{ item.description }}
          </p>
        </router-link>
        <template v-else>
          <h3>{{ title }}</h3>
          <p v-if="withDescription">
            {{ item.description }}
          </p>
        </template>
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import type { MediaImage } from "@/services/fyApi";

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
  to?: any;
  withDescription?: boolean;
  fullscreen?: boolean;
  variant?: "default" | "text";
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  withDescription: true,
  fullscreen: false,
  variant: "default",
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

<script lang="ts">
export default {
  name: "TeaserPanel",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
