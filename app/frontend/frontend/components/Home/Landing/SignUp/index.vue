<script lang="ts">
export default {
  name: "HomeLandingSignUp",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import NumberFlow from "@number-flow/vue";
import SocialLogins from "@/shared/components/SocialLogins/index.vue";
import { OmniauthProviderEnum } from "@/services/fyApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useStats } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useModalQuery } from "@/frontend/composables/useModalQuery";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";

const { t } = useI18n();

const { data: stats } = useStats();

const { openModal } = useModalQuery();

// A pilot already has the hangar the section sells; the way in becomes the
// way back to it.
const { isAuthenticated } = storeToRefs(useSessionStore());

const counts = computed(() =>
  [
    { key: "vehicles", value: stats.value?.vehiclesCount },
    { key: "fleets", value: stats.value?.fleetsCount },
    { key: "ships", value: stats.value?.shipsCountTotal },
  ].filter(
    (count): count is { key: string; value: number } =>
      typeof count.value === "number",
  ),
);

type CommunityLink = {
  key: string;
  icon: string;
  to?: RouteLocationRaw;
  href?: string;
  // Opens over the page rather than leaving it, like the footer's button.
  modal?: "support";
};

const providers = [
  OmniauthProviderEnum.DISCORD,
  OmniauthProviderEnum.CITIZENID,
  OmniauthProviderEnum.TWITCH,
];

const links: CommunityLink[] = [
  {
    key: "discord",
    icon: "fa-brands fa-discord",
    href: "https://discord.gg/6EQKAsb",
  },
  { key: "support", icon: "fa-duotone fa-heart", modal: "support" },
  {
    key: "api",
    icon: "fa-duotone fa-code",
    href: "https://api.fleetyards.net",
  },
];
</script>

<template>
  <section class="home-landing-sign-up" data-test="home-landing-sign-up">
    <span class="home-landing-sign-up__kicker">
      {{
        t(
          isAuthenticated
            ? "home.landing.signUpPanel.kickerSignedIn"
            : "home.landing.signUpPanel.kicker",
        )
      }}
    </span>
    <dl v-if="counts.length" class="home-landing-sign-up__counts">
      <div v-for="count in counts" :key="count.key">
        <dt>{{ t(`home.landing.signUpPanel.counts.${count.key}`) }}</dt>
        <dd><NumberFlow :value="count.value" /></dd>
      </div>
    </dl>
    <h2 class="home-landing-sign-up__title">
      {{
        t(
          isAuthenticated
            ? "home.landing.signUpPanel.titleSignedIn"
            : "home.landing.signUpPanel.title",
        )
      }}
    </h2>
    <div v-if="isAuthenticated" class="home-landing-sign-up__actions">
      <Btn :size="BtnSizesEnum.LG" :to="{ name: 'hangar' }">
        <i class="fa-duotone fa-warehouse" />
        {{ t("home.landing.openHangar") }}
      </Btn>
    </div>
    <div v-else class="home-landing-sign-up__actions">
      <Btn :size="BtnSizesEnum.LG" :to="{ name: 'signup' }">
        <i class="fa-light fa-user-plus" />
        {{ t("home.landing.signUp") }}
      </Btn>
      <span class="home-landing-sign-up__or">
        {{ t("home.landing.signUpPanel.orWith") }}
      </span>
      <SocialLogins only-icons :block="false" :providers="providers" />
    </div>
    <div v-if="!isAuthenticated" class="home-landing-sign-up__login">
      {{ t("home.landing.signUpPanel.loggedIn") }}
      <Btn :variant="BtnVariantsEnum.BARE" :to="{ name: 'login' }">
        <i class="fa-light fa-right-to-bracket" />
        {{ t("home.landing.signUpPanel.login") }}
      </Btn>
    </div>
    <div class="home-landing-sign-up__links">
      <component
        :is="link.to ? 'router-link' : link.href ? 'a' : 'button'"
        v-for="link in links"
        :key="link.key"
        :to="link.to"
        :href="link.href"
        :type="link.modal ? 'button' : undefined"
        :target="link.href ? '_blank' : undefined"
        :rel="link.href ? 'noopener' : undefined"
        class="home-landing-sign-up__link"
        @click="link.modal && openModal(link.modal)"
      >
        <i :class="link.icon" aria-hidden="true" />
        <span>
          <span class="home-landing-sign-up__link-title">
            {{ t(`home.landing.signUpPanel.links.${link.key}.title`) }}
          </span>
          <span class="home-landing-sign-up__link-text">
            {{ t(`home.landing.signUpPanel.links.${link.key}.text`) }}
          </span>
        </span>
      </component>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.home-landing-sign-up {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 26px;
  text-align: center;
}

.home-landing-sign-up__kicker {
  font-family: Orbitron, sans-serif;
  font-size: 14px;
  color: var(--color-primary-tint, #8bb8e0);
  text-transform: uppercase;
  letter-spacing: 0.2em;
}

.home-landing-sign-up__counts {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 24px 64px;
  margin: 0;

  div {
    display: flex;
    flex-direction: column-reverse;
    gap: 10px;
  }

  dt {
    font-size: 16px;
    font-weight: 400;
    color: var(--color-primary-tint, #8bb8e0);
    text-shadow: 0 1px 8px rgb(0 0 0 / 90%);
  }

  dd {
    margin: 0;
    font-family: Orbitron, sans-serif;
    font-size: 52px;
    line-height: 1;
    color: var(--color-lifted);
  }
}

.home-landing-sign-up__title {
  margin: 0;
  font-family: Orbitron, sans-serif;
  font-size: 34px;
  font-weight: 400;
  color: var(--color-lifted);
}

.home-landing-sign-up__actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 10px 12px;
}

.home-landing-sign-up__or,
.home-landing-sign-up__login {
  font-size: 15px;
  color: var(--color-text-dim);
  text-shadow: 0 1px 8px rgb(0 0 0 / 90%);
}

.home-landing-sign-up__login {
  display: flex;
  align-items: center;
  gap: 4px;
}

.home-landing-sign-up__links {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
  width: 100%;
  max-width: 960px;
  margin-top: 18px;
}

.home-landing-sign-up__link {
  display: flex;
  width: 100%;
  font: inherit;
  cursor: pointer;
  align-items: center;
  gap: 14px;
  padding: 16px 18px;
  color: inherit;
  text-align: left;
  text-decoration: none;
  background: rgb(39 43 48 / 82%);
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-surface-slim);
  transition: border-color 0.2s ease;

  &:hover,
  &:focus-visible {
    color: inherit;
    text-decoration: none;
    border-color: var(--color-edge);
  }

  > i {
    font-size: 22px;
    color: var(--color-muted);
  }

  > span {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }
}

.home-landing-sign-up__link-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--color-lifted);
}

.home-landing-sign-up__link-text {
  font-size: 12.5px;
  color: var(--color-text-dim);
}

@media (max-width: 767px) {
  .home-landing-sign-up__counts dd {
    font-size: 36px;
  }

  .home-landing-sign-up__links {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
