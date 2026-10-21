<script lang="ts">
export default {
  name: "HomeLandingSection",
};
</script>

<script lang="ts" setup>
import { useParallax } from "@/shared/composables/useParallax";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // Without one the app's own background shows through, as on the hero.
  image?: string;
  // The first screen: its content sits a little higher, under the header.
  hero?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  image: undefined,
  hero: false,
});

const { t } = useI18n();

const section = ref<HTMLElement | null>(null);

// Kept below the picture's 20% overhang for a section crossing the viewport.
useParallax(section, 0.15);

const { prefersReducedMotion } = useReducedMotion();

const revealed = ref(props.hero);

const next = ref<Element | null>(null);

const scrollToNext = () => {
  next.value?.scrollIntoView({
    behavior: prefersReducedMotion.value ? "auto" : "smooth",
    block: "start",
  });
};

// The hero starts below the page header, so snapping to its own top would
// scroll the header -- the build pills and the support button -- out of view.
// Its snap point is moved up to the top of the page instead.
const alignHeroSnap = () => {
  if (!props.hero || !section.value) return;

  const top = section.value.getBoundingClientRect().top + window.scrollY;

  section.value.style.scrollMarginTop = `${top}px`;
};

let observer: IntersectionObserver | undefined;

onMounted(() => {
  alignHeroSnap();
  window.addEventListener("resize", alignHeroSnap, { passive: true });

  const sibling = section.value?.nextElementSibling;
  next.value = sibling?.classList.contains("landing-section") ? sibling : null;

  if (revealed.value || prefersReducedMotion.value) {
    revealed.value = true;
    return;
  }

  // eslint-disable-next-line compat/compat
  observer = new IntersectionObserver(
    ([entry]) => {
      if (!entry.isIntersecting) return;

      revealed.value = true;
      observer?.disconnect();
    },
    { rootMargin: "0px 0px -15% 0px" },
  );

  if (section.value) observer.observe(section.value);
});

onBeforeUnmount(() => {
  observer?.disconnect();
  window.removeEventListener("resize", alignHeroSnap);
});
</script>

<template>
  <section
    ref="section"
    class="landing-section"
    :class="{
      'landing-section--hero': hero,
      'landing-section--with-art': image,
      'landing-section--revealed': revealed,
    }"
  >
    <div v-if="image" class="landing-section__art-frame" aria-hidden="true">
      <div
        class="landing-section__art"
        :style="{ backgroundImage: `url(${image})` }"
      />
    </div>
    <div class="landing-section__content">
      <slot />
    </div>
    <button
      v-if="next"
      type="button"
      class="landing-section__next"
      :aria-label="t('home.landing.scrollDown')"
      data-test="landing-section-next"
      @click="scrollToNext"
    >
      <i class="fa-light fa-chevron-down" />
    </button>
  </section>
</template>

<style lang="scss" scoped>
// `.main` pads the page by half a gutter; a section cancels it so its
// background reaches the column's edges, and pads its content back.
$bleed: $grid-gutter-width * 0.5;

.landing-section {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: center;
  min-height: 100vh;
  min-height: 100svh;
  margin-right: -$bleed;
  margin-left: -$bleed;
  padding: 96px $bleed;
  scroll-snap-align: start;

  // Shows the app background, so it fades to the black the next section
  // starts from.
  &--hero {
    min-height: calc(100vh - 120px);
    min-height: calc(100svh - 120px);
    padding-top: 24px;
    background: linear-gradient(to bottom, transparent 75%, #000 100%);
  }

  // Opaque, so the app's own background stops behind it rather than showing
  // through a second picture.
  &--with-art {
    background: #000;
  }
}

// Fades the picture into black at the section's top and bottom, so one
// section runs into the next without a seam. On the frame rather than the
// picture, which moves: a fade on it would drift off the edges.
.landing-section__art-frame {
  position: absolute;
  inset: 0;
  z-index: 0;
  overflow: hidden;
  pointer-events: none;
  mask-image: linear-gradient(
    to bottom,
    transparent 0%,
    #000 25%,
    #000 75%,
    transparent 100%
  );
}

// Taller than its section, so the parallax shift never shows an edge, and as
// strong as the app background.
.landing-section__art {
  position: absolute;
  top: -20%;
  right: 0;
  bottom: -20%;
  left: 0;
  background-position: center;
  background-size: cover;
  opacity: 0.4;
  transform: translate3d(0, var(--parallax-offset, 0), 0);
  will-change: transform;
}

.landing-section__content {
  position: relative;
  z-index: 1;
  opacity: 0;
  transform: translateY(32px);
  transition:
    opacity 0.7s ease-out,
    transform 0.7s ease-out;

  .landing-section--revealed & {
    opacity: 1;
    transform: none;
  }

  // Above the next section, which paints later: the search's matches open
  // downwards and would otherwise slide under its picture.
  .landing-section--hero & {
    z-index: 2;
  }
}

.landing-section__next {
  position: absolute;
  bottom: 12px;
  left: 50%;
  z-index: 1;
  padding: 8px 16px;
  color: var(--color-text-dim, #959595);
  font-size: 2rem;
  background: none;
  border: 0;
  transform: translateX(-50%);
  cursor: pointer;
  transition: color 0.2s ease;

  &:hover,
  &:focus-visible {
    color: var(--color-lifted, #eee);
  }
}

@media (prefers-reduced-motion: reduce) {
  .landing-section__content {
    opacity: 1;
    transform: none;
    transition: none;
  }
}

@media (max-width: 767px) {
  .landing-section {
    min-height: 0;
    padding-top: 56px;
    padding-bottom: 72px;

    &--hero {
      min-height: calc(100svh - 96px);
      padding-top: 16px;
    }
  }
}
</style>
