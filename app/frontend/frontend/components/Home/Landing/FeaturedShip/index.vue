<script lang="ts">
export default {
  name: "HomeLandingFeaturedShip",
};
</script>

<script lang="ts" setup>
import { type HomepageFeaturedShip } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  ship: HomepageFeaturedShip;
};

const props = defineProps<Props>();

const { t } = useI18n();

// A render is large; it fades in once it has arrived rather than painting in
// strips.
const loaded = ref(false);

const imageRef = ref<HTMLImageElement | null>(null);

onMounted(() => {
  if (imageRef.value?.complete) loaded.value = true;
});

const image = computed(
  () => props.ship.image?.largeUrl || props.ship.image?.url,
);
</script>

<!-- The ship the team features: its cut-out render over a faint glow, named
     in a quiet caption at its lower right. The whole of it opens the ship's
     page. -->
<template>
  <router-link
    :to="{ name: 'ship', params: { slug: ship.slug } }"
    class="home-featured-ship"
    :class="{ 'home-featured-ship--loaded': loaded }"
    data-test="home-featured-ship"
  >
    <img
      v-if="image"
      ref="imageRef"
      :src="image"
      alt=""
      class="home-featured-ship__image"
      :class="{ 'home-featured-ship__image--loaded': loaded }"
      @load="loaded = true"
    />
    <span
      class="home-featured-ship__caption"
      :class="{ 'home-featured-ship__caption--shown': loaded || !image }"
    >
      <span class="home-featured-ship__label">
        {{ t("home.landing.featuredShip") }}
      </span>
      <span class="home-featured-ship__name">{{ ship.name }}</span>
      <span v-if="ship.manufacturerName" class="home-featured-ship__maker">
        {{ ship.manufacturerName }}
      </span>
    </span>
  </router-link>
</template>

<style lang="scss" scoped>
.home-featured-ship {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: inherit;
  text-decoration: none;

  &::before {
    position: absolute;
    inset: 8% 4%;
    background: radial-gradient(
      ellipse at center,
      rgb(66 139 202 / 0.22) 0%,
      rgb(66 139 202 / 0) 65%
    );
    content: "";
    pointer-events: none;
    // Sized from the render, which has no height until it loads: shown
    // before, the glow is a thin line across the column.
    opacity: 0;
    transition: opacity 0.6s ease;
  }

  &--loaded::before {
    opacity: 1;
  }
}

// Capped both ways: a wide window must not blow the render up past its
// column, and a tall render must not push the hero past the screen.
.home-featured-ship__image {
  position: relative;
  width: 112%;
  max-width: 800px;
  height: auto;
  max-height: 70vh;
  object-fit: contain;
  filter: drop-shadow(0 30px 40px rgb(0 0 0 / 0.6));
  opacity: 0;
  transition:
    opacity 0.6s ease,
    transform 0.4s ease;

  &--loaded {
    opacity: 1;
  }

  .home-featured-ship:hover & {
    transform: translateY(-4px);
  }
}

// Under the render rather than on it: a large ship fills its frame to the
// corners. It waits for the render, so it does not sit up against an empty
// frame and drop when the image lands, and settles downwards into place.
.home-featured-ship__caption {
  position: relative;
  align-self: flex-end;
  margin: 8px 8% 0 0;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  text-align: right;
  opacity: 0;
  transform: translateY(-16px);
  transition:
    opacity 0.5s ease 0.35s,
    transform 0.5s ease 0.35s;

  &--shown {
    opacity: 1;
    transform: none;
  }
}

.home-featured-ship__label {
  color: var(--color-text-dim, #959595);
  font-family: Orbitron, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

// Brightens like a link, rather than turning blue.
.home-featured-ship__name {
  color: var(--color-lifted, #eee);
  font-size: 13.5px;
  font-weight: 600;
  transition: color 0.2s ease;

  .home-featured-ship:hover &,
  .home-featured-ship:focus-visible & {
    color: #fff;
  }
}

.home-featured-ship__maker {
  color: var(--color-text-dim, #959595);
  font-size: 12px;
}

@media (max-width: 767px) {
  .home-featured-ship {
    flex-direction: column;
  }

  .home-featured-ship__image {
    width: 92%;
  }

  .home-featured-ship__caption {
    align-self: center;
    align-items: center;
    margin: 4px 0 0;
    text-align: center;
  }
}

@media (prefers-reduced-motion: reduce) {
  .home-featured-ship__caption {
    transform: none;
  }

  .home-featured-ship__image {
    transition: none;

    .home-featured-ship:hover & {
      transform: none;
    }
  }
}
</style>
