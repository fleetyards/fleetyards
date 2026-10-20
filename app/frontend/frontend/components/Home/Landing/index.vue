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
import LandingStats from "@/frontend/components/Home/Landing/Stats/index.vue";
import LandingFeatures from "@/frontend/components/Home/Landing/Features/index.vue";
import LandingPatch from "@/frontend/components/Home/Landing/Patch/index.vue";
import LandingGameEvents from "@/frontend/components/Home/Landing/GameEvents/index.vue";
import LandingLatestShips from "@/frontend/components/Home/Landing/LatestShips/index.vue";
import LandingSignUp from "@/frontend/components/Home/Landing/SignUp/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <Teleport to="#header-right">
    <SupportBtn :size="BtnSizesEnum.MD" page />
  </Teleport>

  <section class="home-landing__hero" data-test="home-landing">
    <HomeBuildPills />
    <Heading hero>{{ t("home.landing.title") }}</Heading>
    <p class="home-landing__lede">{{ t("home.landing.lede") }}</p>
    <HomeSearch class="home-landing__search" />
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
  </section>

  <LandingStats />

  <section class="home-landing__section">
    <Heading :level="HeadingLevelEnum.H2">
      {{ t("home.landing.features.title") }}
    </Heading>
    <p class="home-landing__subline">
      {{ t("home.landing.features.subline") }}
    </p>
    <LandingFeatures />
  </section>

  <LandingPatch class="home-landing__section" />
  <LandingGameEvents class="home-landing__section" />
  <LandingLatestShips class="home-landing__section" />
  <LandingSignUp class="home-landing__section" />
</template>

<style lang="scss" scoped>
.home-landing__hero {
  max-width: 760px;
  padding: 16px 0 8px;
}

.home-landing__lede {
  max-width: 60ch;
  margin: 0 0 24px;
  color: var(--color-text, #c8c8c8);
  font-size: 1.125rem;
  line-height: 1.75rem;
}

.home-landing__search {
  max-width: 620px;
}

.home-landing__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 16px;
}

.home-landing__section {
  margin-top: 48px;
}

.home-landing__subline {
  margin: 0 0 12px;
  color: var(--color-text-dim, #959595);
}

@media (max-width: 575px) {
  .home-landing__actions :deep(.btn) {
    flex: 1 1 auto;
  }
}
</style>
