<script lang="ts">
export default {
  name: "AppFooter",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import CommunityLogo from "@/shared/components/CommunityLogo/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18nStore } from "@/shared/stores/i18n";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  version: string;
  codename: string;
  gitRevision: string;
  online: boolean;
};

defineProps<Props>();

const { t, availableLocales, currentLocale } = useI18n();

const i18nStore = useI18nStore();

const localeMapping = {
  de: "Deutsch",
  en: "English",
  es: "Español",
  fr: "Français",
  it: "Italiano",
  zh: "中文",
  "zh-CN": "中文 (简体)",
  "zh-TW": "中文 (繁體)",
};

const copyrightOwner = computed(() => {
  return window.COPYRIGHT_OWNER;
});

const scDataVersion = computed(() => {
  return window.SC_DATA_VERSION;
});

const locales = computed(() => {
  return availableLocales() as (keyof typeof localeMapping)[];
});

const activeLocale = (locale: string) => {
  return (
    locale === currentLocale() ||
    (!locale.includes("zh") && locale === currentLocale().split("-")[0])
  );
};

const comlink = useComlink();

const openSupportModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/SupportBtn/Modal/index.vue"),
    wide: true,
  });
};

const setLocale = (locale: string) => {
  i18nStore.locale = locale;
};
</script>

<template>
  <footer class="app-footer">
    <div class="app-footer-border app-footer-border-top">
      <div class="app-footer-border-left" />
      <div class="app-footer-border-right" />
    </div>
    <div class="app-footer-inner">
      <div class="app-footer-inner-border app-footer-inner-border-top">
        <div class="app-footer-inner-border-bg" />
      </div>
      <div class="app-footer-links">
        <a
          v-tooltip="'Roberts Space Industries'"
          href="https://robertsspaceindustries.com/"
          target="_blank"
          rel="noopener"
        >
          RSI
        </a>
        |
        <router-link :to="{ name: 'privacy-policy' }">
          {{ t("nav.privacyPolicy") }}
        </router-link>
        |
        <router-link :to="{ name: 'impressum' }">
          {{ t("nav.impressum") }}
        </router-link>
        |
        <a href="https://api.fleetyards.net" target="_blank" rel="noopener">
          {{ t("nav.api") }}
        </a>
        |
        <BtnDropdown
          :text-inline="true"
          :inline="true"
          :size="BtnSizesEnum.SMALL"
          :variant="BtnVariantsEnum.LINK"
          :expand-top="true"
        >
          <template #label>
            <i class="fad fa-language" /> {{ currentLocale() }}
          </template>
          <Btn
            v-for="locale in locales"
            :key="`locale-${locale}`"
            :size="BtnSizesEnum.SMALL"
            :active="activeLocale(locale)"
            @click="setLocale(locale)"
          >
            {{ localeMapping[locale] }} - {{ locale }}
          </Btn>
        </BtnDropdown>
      </div>
      <div class="app-footer-social-links">
        <a
          v-tooltip="'Discord'"
          href="https://discord.gg/6EQKAsb"
          target="_blank"
          rel="noopener"
          aria-label="Discrod"
        >
          <i class="fab fa-discord" />
        </a>
        <a
          v-tooltip="'Github'"
          href="https://github.com/fleetyards"
          target="_blank"
          rel="noopener"
          aria-label="Github"
        >
          <i class="fab fa-github" />
        </a>
        <a
          v-tooltip="'Bluesky'"
          href="https://bsky.app/profile/fleetyards.net"
          target="_blank"
          rel="noopener"
          aria-label="Bluesky"
        >
          <i class="fab fa-bluesky" />
        </a>
        <a
          v-tooltip="'Mastodon'"
          href="https://starcitizen.social/@fleetyards"
          target="_blank"
          rel="noopener"
          aria-label="Mastodon"
        >
          <i class="fab fa-mastodon" />
        </a>
        <a
          v-tooltip="'Instagram'"
          href="https://www.instagram.com/fleetyardsnet/"
          target="_blank"
          rel="noopener"
          aria-label="Instagram"
        >
          <i class="fab fa-instagram" />
        </a>
      </div>
      <div class="app-footer-support">
        <Btn inline :variant="BtnVariantsEnum.LINK" @click="openSupportModal">
          {{ t("labels.supportUs") }}
          <i class="fa fa-heart" />
        </Btn>
      </div>
      <div class="app-footer-disclaimer">
        <p>
          <span>Copyright &copy; {{ new Date().getFullYear() }}</span>
          {{ copyrightOwner }}
        </p>
        <p class="app-footer-disclaimer-rsi">
          This is an unofficial Star Citizen fansite, not affiliated with the
          Cloud Imperium group of companies.
          <br />
          All content on this site not authored by its host or users are
          property of their respective owners.
          <br />
          Star Citizen®, Squadron 42®, Roberts Space Industries®, and Cloud
          Imperium® are
          <br />
          registered trademarks of Cloud Imperium Rights LLC. All rights
          reserved.
        </p>
      </div>
      <div class="app-footer-community-logo">
        <CommunityLogo />
      </div>
      <div class="app-footer-version">
        {{ codename }} ({{ version }})
        <span
          v-tooltip="gitRevision"
          :class="{
            online: online,
          }"
          class="git-revision"
        >
          <span class="hidden">{{ gitRevision }}</span>
          <i class="far fa-fingerprint" />
        </span>
      </div>
      <div class="app-footer-sc-data-version">
        {{ t("labels.scDataVersion") }}: {{ scDataVersion }}
      </div>
    </div>
  </footer>
</template>

<style lang="scss" scoped>
@import "index";
</style>
