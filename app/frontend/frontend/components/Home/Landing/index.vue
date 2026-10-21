<script lang="ts">
export default {
  name: "HomeLanding",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import SupportBtn from "@/frontend/components/SupportBtn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import HomeSearch from "@/frontend/components/Home/Search/index.vue";
import HomeBuildPills from "@/frontend/components/Home/BuildPills/index.vue";
import LandingSection from "@/frontend/components/Home/Landing/Section/index.vue";
import LandingStats from "@/frontend/components/Home/Landing/Stats/index.vue";
import LandingFeatures from "@/frontend/components/Home/Landing/Features/index.vue";
import LandingPatch from "@/frontend/components/Home/Landing/Patch/index.vue";
import LandingGameEvents from "@/frontend/components/Home/Landing/GameEvents/index.vue";
import LandingLatestShips from "@/frontend/components/Home/Landing/LatestShips/index.vue";
import LandingSignUp from "@/frontend/components/Home/Landing/SignUp/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import logo from "@/images/pride/logo-planet.png";
import featuresArt from "@/images/bg-3.webp";
import patchArt from "@/images/bg-5.webp";
import shipsArt from "@/images/bg-7.webp";
import signUpArt from "@/images/bg-hangar.webp";

const { t } = useI18n();

const mobile = useMobile();

// Snapping belongs to this page alone, and `html` is the element that scrolls.
onMounted(() => document.documentElement.classList.add("home-landing-snap"));
onBeforeUnmount(() =>
  document.documentElement.classList.remove("home-landing-snap"),
);
</script>

<template>
  <Teleport to="#header-left">
    <HomeBuildPills class="home-landing__pills" />
  </Teleport>
  <Teleport to="#header-right">
    <SupportBtn :size="BtnSizesEnum.MD" page />
  </Teleport>

  <LandingSection hero data-test="home-landing">
    <div class="home-landing__hero">
      <img
        :src="logo"
        alt=""
        class="home-landing__logo"
        width="150"
        height="101"
      />
      <Heading hero class="home-landing__welcome">
        <small class="home-landing__welcome-prefix">
          {{ t("headlines.welcome") }}
        </small>
        {{ t("title.default") }}
      </Heading>
      <p class="home-landing__tagline">{{ t("home.landing.title") }}</p>
      <p class="home-landing__lede">{{ t("home.landing.lede") }}</p>
      <HomeSearch class="home-landing__search" :autofocus="!mobile" />
      <div class="home-landing__actions">
        <Btn :size="BtnSizesEnum.LG" :to="{ name: 'signup' }">
          <i class="fa-light fa-user-plus" />
          {{ t("home.landing.signUp") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.LG"
          :variant="BtnVariantsEnum.GHOST"
          :to="{ name: 'ships' }"
        >
          {{ t("home.landing.browseShips") }}
          <i class="fa-light fa-chevron-right" />
        </Btn>
      </div>
    </div>
  </LandingSection>

  <LandingSection :image="featuresArt">
    <LandingStats />
    <div class="home-landing__features">
      <Heading :level="HeadingLevelEnum.H2">
        {{ t("home.landing.features.title") }}
      </Heading>
      <p class="home-landing__subline">
        {{ t("home.landing.features.subline") }}
      </p>
      <LandingFeatures />
    </div>
  </LandingSection>

  <LandingSection :image="patchArt">
    <LandingPatch />
  </LandingSection>

  <LandingSection :image="shipsArt">
    <LandingGameEvents class="home-landing__events" />
    <LandingLatestShips />
  </LandingSection>

  <LandingSection :image="signUpArt">
    <LandingSignUp />
  </LandingSection>
</template>

<style lang="scss" scoped>
.home-landing__pills {
  margin-bottom: 0;
}

.home-landing__hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  max-width: 760px;
  margin: 0 auto;
  text-align: center;
}

.home-landing__logo {
  width: 150px;
  height: auto;
  margin-bottom: 8px;
}

.home-landing__welcome {
  align-items: center;
}

.home-landing__welcome-prefix {
  color: var(--color-text-dim, #959595);
  font-size: 1rem;
}

.home-landing__tagline {
  margin: 0 0 8px;
  color: var(--color-lifted, #eee);
  font-size: 1.375rem;
  line-height: 1.875rem;
}

.home-landing__lede {
  max-width: 60ch;
  margin: 0 auto 32px;
  color: var(--color-text, #c8c8c8);
  font-size: 1.125rem;
  line-height: 1.75rem;
}

.home-landing__search {
  width: 100%;
  max-width: 620px;
}

.home-landing__actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 12px;
  margin-top: 20px;
}

.home-landing__features {
  margin-top: 64px;
}

.home-landing__events {
  margin-bottom: 64px;
}

.home-landing__subline {
  margin: 0 0 12px;
  color: var(--color-text-dim, #959595);
}

@media (max-width: 767px) {
  .home-landing__logo {
    width: 110px;
  }

  .home-landing__features {
    margin-top: 40px;
  }

  .home-landing__events {
    margin-bottom: 40px;
  }

  .home-landing__actions :deep(.btn) {
    flex: 1 1 auto;
  }
}
</style>

<style lang="scss">
html.home-landing-snap {
  scroll-snap-type: y proximity;
}
</style>
