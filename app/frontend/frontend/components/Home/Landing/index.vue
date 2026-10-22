<script lang="ts">
export default {
  name: "HomeLanding",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import SupportBtn from "@/frontend/components/SupportBtn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import HomeSearch from "@/frontend/components/Home/Search/index.vue";
import HomeBuildPills from "@/frontend/components/Home/BuildPills/index.vue";
import LandingSection from "@/frontend/components/Home/Landing/Section/index.vue";
import LandingStats from "@/frontend/components/Home/Landing/Stats/index.vue";
import LandingFeaturedShip from "@/frontend/components/Home/Landing/FeaturedShip/index.vue";
import LandingFeatures from "@/frontend/components/Home/Landing/Features/index.vue";
import LandingPatch from "@/frontend/components/Home/Landing/Patch/index.vue";
import LandingGameEvents from "@/frontend/components/Home/Landing/GameEvents/index.vue";
import LandingLatestShips from "@/frontend/components/Home/Landing/LatestShips/index.vue";
import LandingSignUp from "@/frontend/components/Home/Landing/SignUp/index.vue";
import { useGameEvents, useHomepage } from "@/services/fyApi";
import { useMediaQuery } from "@vueuse/core";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { usePatchLoadingScreens } from "@/frontend/composables/usePatchLoadingScreens";
import logo from "@/images/pride/logo-planet.png";
import featuresArt from "@/images/bg-5.webp";
import patchArt from "@/images/bg-3.webp";
import shipsArt from "@/images/bg-6.webp";
import signUpArt from "@/images/bg-0.webp";

const { t } = useI18n();

const { isAuthenticated } = storeToRefs(useSessionStore());

const mobile = useMobile();

// What the team curates: the searches offered under the field and the ship
// beside it. Without a ship the hero stays a single centred column.
const { data: homepage, isPending: homepagePending } = useHomepage();

// Held back until the settings answer: whether a ship is featured decides the
// layout, and switching from one column to two in front of the reader is a
// jump. A slow answer does not keep the hero hidden for long.
const heroReady = ref(false);

watch(
  homepagePending,
  (pending) => {
    if (!pending) heroReady.value = true;
  },
  { immediate: true },
);

let heroFallback: ReturnType<typeof setTimeout> | undefined;

onMounted(() => {
  heroFallback = setTimeout(() => {
    heroReady.value = true;
  }, 1500);
});

onBeforeUnmount(() => clearTimeout(heroFallback));

const featuredShip = computed(() => homepage.value?.featuredShip);

// The same query the events list asks, so this reads its answer rather than a
// second request.
const { data: gameEvents, isPending: gameEventsPending } = useGameEvents({
  perPage: "6",
});

// The events grid lays out three a row from this width, one below it.
const eventsInThree = useMediaQuery("(min-width: 992px)");

const eventColumns = computed(() => (eventsInThree.value ? 3 : 1));

// The events and the ships share one screen: two rows of events leave room
// for one row of ships.
const shipRows = computed(() => {
  const events = gameEvents.value?.items.length || 0;

  return Math.ceil(events / eventColumns.value) >= 2 ? 1 : 2;
});

const { pick: pickLoadingScreen, screens: loadingScreens } =
  usePatchLoadingScreens();

// The patch section stands on the patch's own loading screen when it shipped
// one.
const patchBackground = computed(() => pickLoadingScreen(0, patchArt));
</script>

<template>
  <Teleport to="#header-left">
    <HomeBuildPills class="home-landing__pills" />
  </Teleport>
  <Teleport to="#header-right">
    <SupportBtn :size="BtnSizesEnum.MD" page />
  </Teleport>

  <LandingSection hero data-test="home-landing">
    <div
      class="home-landing__hero"
      :class="{
        'home-landing__hero--featured': featuredShip,
        'home-landing__hero--ready': heroReady,
      }"
    >
      <div class="home-landing__copy">
        <h1 class="home-landing__lockup">
          <img
            :src="logo"
            alt=""
            class="home-landing__logo"
            width="112"
            height="75"
          />
          <span class="home-landing__lockup-text">
            <span class="home-landing__welcome">{{
              t("headlines.welcome")
            }}</span>
            <span class="home-landing__wordmark">{{ t("title.default") }}</span>
          </span>
        </h1>
        <p class="home-landing__tagline">{{ t("home.landing.title") }}</p>
        <p class="home-landing__lede">{{ t("home.landing.lede") }}</p>
        <HomeSearch
          class="home-landing__search"
          :autofocus="!mobile"
          :suggestions="homepage?.searchSuggestions"
        />
        <div class="home-landing__actions">
          <Btn v-if="isAuthenticated" :to="{ name: 'hangar' }">
            <i class="fa-duotone fa-warehouse" />
            {{ t("home.landing.openHangar") }}
          </Btn>
          <Btn v-else :to="{ name: 'signup' }">
            <i class="fa-light fa-user-plus" />
            {{ t("home.landing.signUp") }}
          </Btn>
          <router-link :to="{ name: 'ships' }" class="home-landing__link">
            {{ t("home.landing.browseShips") }}
            <i class="fa-light fa-chevron-right" />
          </router-link>
        </div>
        <LandingStats
          v-if="featuredShip"
          class="home-landing__stats home-landing__stats--start"
        />
      </div>
      <LandingFeaturedShip v-if="featuredShip" :ship="featuredShip" />
    </div>
    <LandingStats v-if="!featuredShip" class="home-landing__stats" />
  </LandingSection>

  <!-- What a visitor can do here comes second; a pilot already knows, so for
       them it moves down to just before the close. -->
  <LandingSection v-if="!isAuthenticated" :image="featuresArt">
    <Heading :level="HeadingLevelEnum.H2" hero>
      {{ t("home.landing.features.title") }}
    </Heading>
    <p class="home-landing__subline">
      {{ t("home.landing.features.subline") }}
    </p>
    <LandingFeatures />
  </LandingSection>

  <LandingSection
    :image="patchBackground"
    :quiet-art="loadingScreens.length > 0"
  >
    <LandingPatch />
  </LandingSection>

  <LandingSection :image="shipsArt">
    <LandingGameEvents class="home-landing__events" />
    <LandingLatestShips v-if="!gameEventsPending" :rows="shipRows" />
  </LandingSection>

  <LandingSection v-if="isAuthenticated" :image="featuresArt">
    <Heading :level="HeadingLevelEnum.H2" hero>
      {{ t("home.landing.features.title") }}
    </Heading>
    <p class="home-landing__subline">
      {{ t("home.landing.features.subline") }}
    </p>
    <LandingFeatures />
  </LandingSection>

  <LandingSection :image="signUpArt">
    <LandingSignUp />
  </LandingSection>
</template>

<style lang="scss" scoped>
.home-landing__pills {
  margin-bottom: 0;
}

// One centred column; with a featured ship, the copy on the left and the ship
// beside it.
.home-landing__hero {
  opacity: 0;
  transform: translateY(12px);
  transition:
    opacity 0.5s ease,
    transform 0.5s ease;

  display: grid;
  grid-template-columns: minmax(0, 1fr);
  align-items: center;
  gap: 32px;
  max-width: 820px;
  margin: 0 auto;

  &--featured {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    max-width: none;
  }

  &--ready {
    opacity: 1;
    transform: none;
  }
}

@media (prefers-reduced-motion: reduce) {
  .home-landing__hero {
    transform: none;
  }
}

.home-landing__copy {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  --home-search-try-justify: center;

  .home-landing__hero--featured & {
    align-items: flex-start;
    max-width: 620px;
    text-align: left;
    --home-search-try-justify: flex-start;
  }
}

.home-landing__lockup {
  display: flex;
  align-items: center;
  gap: 16px;
  margin: 0 0 28px;
  font-weight: 400;
}

.home-landing__logo {
  width: 112px;
  height: auto;
}

.home-landing__lockup-text {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 4px;
}

.home-landing__welcome {
  color: var(--color-text-dim, #959595);
  font-family: Orbitron, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.home-landing__wordmark {
  color: var(--color-lifted, #eee);
  font-family: Orbitron, sans-serif;
  font-size: 34px;
  line-height: 1.1;
}

.home-landing__tagline {
  margin: 0 0 12px;
  color: #fff;
  font-size: 42px;
  font-weight: 600;
  line-height: 1.18;
  letter-spacing: -0.01em;
  text-wrap: balance;
}

.home-landing__lede {
  max-width: 46ch;
  margin: 0 0 32px;
  color: var(--color-text, #c8c8c8);
  font-size: 18px;
  line-height: 28px;
}

.home-landing__search {
  width: 100%;
  max-width: 720px;
}

.home-landing__actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 20px;
  margin-top: 32px;
}

.home-landing__link {
  color: var(--color-text, #c8c8c8);
  font-size: 15px;

  &:hover,
  &:focus-visible {
    color: #fff;
  }
}

.home-landing__stats {
  margin-top: 56px;

  // Beside a featured ship the numbers sit under the copy, flush with it.
  &--start {
    --home-landing-stats-justify: flex-start;
    --home-landing-stats-align: flex-start;
    --home-landing-stats-first-padding: 0;
  }
}

.home-landing__events {
  margin-bottom: 64px;
}

.home-landing__subline {
  margin: 0 0 12px;
  color: var(--color-text-dim, #959595);
}

@media (max-width: 991px) {
  .home-landing__hero--featured {
    grid-template-columns: minmax(0, 1fr);
  }

  .home-landing__hero--featured .home-landing__copy {
    align-items: center;
    max-width: none;
    text-align: center;
    --home-search-try-justify: center;
  }

  .home-landing__stats--start {
    --home-landing-stats-justify: center;
    --home-landing-stats-align: center;
    --home-landing-stats-first-padding: 40px;
  }
}

@media (max-width: 767px) {
  .home-landing__lockup {
    gap: 12px;
    margin-bottom: 20px;
  }

  .home-landing__logo {
    width: 72px;
  }

  .home-landing__wordmark {
    font-size: 22px;
  }

  .home-landing__tagline {
    font-size: 26px;
    line-height: 1.25;
  }

  .home-landing__lede {
    margin-bottom: 22px;
    font-size: 15px;
    line-height: 23px;
  }

  .home-landing__actions {
    flex-direction: column;
    align-items: stretch;
    width: 100%;
    gap: 12px;
  }

  .home-landing__stats {
    margin-top: 32px;
  }

  .home-landing__events {
    margin-bottom: 40px;
  }
}
</style>

<style lang="scss">
// The last section runs into the footer: the page container's bottom margin
// would leave a strip of the app background between them.
.main.home:has(.landing-section) {
  margin-bottom: 0;
}
</style>
