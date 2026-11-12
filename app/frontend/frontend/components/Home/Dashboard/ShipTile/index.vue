<script lang="ts">
export default {
  name: "HomeDashboardShipTile",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { type MediaFile } from "@/services/fyApi";

interface Props {
  name: string;
  to: RouteLocationRaw;
  image?: MediaFile;
  sub?: string;
  tags?: string[];
}

const props = withDefaults(defineProps<Props>(), {
  image: undefined,
  sub: undefined,
  tags: () => [],
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
  <router-link :to="to" class="home-ship-tile" :title="name">
    <img :src="imageUrl" alt="" class="home-ship-tile__image" loading="lazy" />
    <span v-if="tags.length" class="home-ship-tile__tags">
      <span
        v-for="item in tags"
        :key="item"
        class="home-ship-tile__tag"
        data-test="home-ship-tile-tag"
      >
        {{ item }}
      </span>
    </span>
    <span class="home-ship-tile__body">
      <span class="home-ship-tile__name">{{ name }}</span>
      <span v-if="sub" class="home-ship-tile__sub">{{ sub }}</span>
    </span>
  </router-link>
</template>

<style lang="scss" scoped>
// The picture is the card: it fills the frame, and the name sits on its lower
// edge over a shade that keeps it readable on any picture.
.home-ship-tile {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  min-width: 0;
  min-height: 140px;
  overflow: hidden;
  border: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  border-radius: 10px;
  background: var(--color-gray-darker, #272b30);
  color: inherit;
  text-decoration: none;
  transition: border-color 150ms ease;

  &:hover {
    border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  }
}

.home-ship-tile__image {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.home-ship-tile__tags {
  position: absolute;
  top: 8px;
  right: 8px;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  max-width: calc(100% - 16px);
}

.home-ship-tile__tag {
  max-width: 100%;
  overflow: hidden;
  padding: 2px 8px;
  border: 1px solid rgb(66 139 202 / 0.6);
  border-radius: 11px;
  background: rgb(26 29 33 / 0.9);
  color: #8dbbe3;
  font-size: 0.625rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-overflow: ellipsis;
  text-transform: uppercase;
  white-space: nowrap;
}

.home-ship-tile__body {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
  padding: 28px 12px 10px;
  background: linear-gradient(
    180deg,
    rgb(0 0 0 / 0) 0%,
    rgb(0 0 0 / 0.75) 60%,
    rgb(0 0 0 / 0.85) 100%
  );
}

.home-ship-tile__name,
.home-ship-tile__sub {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.home-ship-tile__name {
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.home-ship-tile__sub {
  color: var(--color-text, #c8c8c8);
  font-size: 0.75rem;
}
</style>
