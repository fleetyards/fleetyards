<script lang="ts">
export default {
  name: "HomeSearchResultLabel",
};
</script>

<script lang="ts" setup>
import AppIcon from "@/shared/components/AppIcon/index.vue";
import MissionText from "@/frontend/components/MissionText/index.vue";
import LocationGlobe from "@/frontend/components/Locations/Globe/index.vue";
import LocationKindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import { catalogueTokenIcon } from "@/shared/utils/CatalogueTokens";
import { sunStyle } from "@/shared/utils/LocationGlobe";
import { type SearchResult } from "@/services/fyApi";

type Props = {
  result: SearchResult;
  // Marked where it occurs in the name, so the reader sees why it matched.
  query?: string;
};

const props = withDefaults(defineProps<Props>(), {
  query: undefined,
});

const image = computed(
  () => props.result.image?.smallUrl || props.result.image?.url,
);

// A place's picture fills the frame. Everything else -- a ship's angled
// render, an item's picture -- is a cut-out, which a crop would cut into.
const cover = computed(() => props.result.type === "Location");

const appearance = computed(() => props.result.appearance);

// A body and a star are drawn, as the starmap draws them, whether or not a
// picture of them exists; a system is drawn as its star.
const art = computed(() => {
  const kind = appearance.value?.kind;

  if (kind === "planet" || kind === "moon") return "globe";
  if (kind === "star" || kind === "system") return "sun";

  return undefined;
});

const sun = computed(() =>
  sunStyle({ kind: "star", color: appearance.value?.color }),
);

const nameParts = computed(() => {
  const name = props.result.name;
  const query = props.query?.trim();
  const at = query ? name.toLowerCase().indexOf(query.toLowerCase()) : -1;

  if (!query || at < 0) return [{ text: name, match: false }];

  return [
    { text: name.slice(0, at), match: false },
    { text: name.slice(at, at + query.length), match: true },
    { text: name.slice(at + query.length), match: false },
  ].filter((part) => part.text);
});
</script>

<!-- One match: a body or star drawn, else its picture, else a small icon --
     never as wide as a picture would be. Then its name, and below it what tells
     it apart from the items that share the name. -->
<template>
  <span class="search-result-label">
    <span
      v-if="art"
      class="search-result-label__art"
      aria-hidden="true"
      data-test="search-result-art"
    >
      <LocationGlobe
        v-if="art === 'globe' && appearance"
        :location="appearance"
        class="search-result-label__globe"
      />
      <span
        v-else
        class="search-result-label__sun"
        :class="{ 'search-result-label__sun--unstable': appearance?.flare }"
        :style="sun"
      />
    </span>
    <span
      v-else-if="image"
      class="search-result-label__thumb"
      aria-hidden="true"
    >
      <img
        :src="image"
        alt=""
        loading="lazy"
        class="search-result-label__image"
        :class="{ 'search-result-label__image--cover': cover }"
      />
    </span>
    <span
      v-else
      class="search-result-label__icon"
      aria-hidden="true"
      data-test="search-result-icon"
    >
      <LocationKindIcon v-if="appearance" :kind="appearance.kind" />
      <AppIcon v-else :icon="catalogueTokenIcon(result.type)" />
    </span>
    <span class="search-result-label__text">
      <span class="search-result-label__name">
        <!-- A mission's name is a game template, shown as the mission list
             shows it; its placeholders would split a marked match anyway. -->
        <MissionText v-if="result.type === 'GameMission'" :text="result.name" />
        <template v-else>
          <template v-for="(part, index) in nameParts" :key="index">
            <mark v-if="part.match" class="search-result-label__match">{{
              part.text
            }}</mark>
            <template v-else>{{ part.text }}</template>
          </template>
        </template>
      </span>
      <span v-if="result.detail" class="search-result-label__detail">
        {{ result.detail }}
      </span>
    </span>
  </span>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Locations/sun";

.search-result-label {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.search-result-label__thumb {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  width: 64px;
  height: 40px;
  overflow: hidden;
  background: var(--color-control, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: 6px;
}

// A drawn body or star needs no frame: it is round, and as tall as a picture.
.search-result-label__art {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
}

.search-result-label__globe {
  display: block;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background-color: #1d2329;
  border: 1px solid
    var(--globe-border, var(--color-edge-soft, rgb(122 130 136 / 0.55)));
}

.search-result-label__sun {
  @include location-sun;

  display: block;
  width: 22px;
  height: 22px;

  &--unstable {
    @include location-sun-unstable;
  }
}

// Decoration beside the name, quieter than it -- and only the room a glyph
// needs, never the width of a picture.
.search-result-label__icon {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  width: 20px;
  color: var(--color-muted, #7a8288);
  font-size: 15px;
}

.search-result-label__image {
  width: 100%;
  height: 100%;
  object-fit: contain;

  &--cover {
    object-fit: cover;
  }
}

.search-result-label__text {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.search-result-label__name {
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-size: 13.5px;
  font-weight: 600;
  line-height: 1.35;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.search-result-label__match {
  padding: 0;
  color: #fff;
  background: rgb(66 139 202 / 0.3);
  border-radius: 2px;
}

.search-result-label__detail {
  overflow: hidden;
  color: var(--color-text-dim, #959595);
  font-size: 12px;
  line-height: 1.35;
  white-space: nowrap;
  text-overflow: ellipsis;
}
</style>
