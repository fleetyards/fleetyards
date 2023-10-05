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
          {{ $t("nav.privacyPolicy") }}
        </router-link>
        |
        <router-link :to="{ name: 'impressum' }">
          {{ $t("nav.impressum") }}
        </router-link>
        |
        <a href="https://api.fleetyards.net" target="_blank" rel="noopener">
          {{ $t("nav.api") }}
        </a>
        |
        <BtnDropdown
          :text-inline="true"
          :inline="true"
          size="small"
          variant="link"
          :expand-top="true"
        >
          <template #label>
            <i class="fad fa-language" /> {{ currentLocale }}
          </template>
          <Btn
            v-for="locale in locales"
            :key="`locale-${locale}`"
            size="small"
            variant="dropdown"
            :active="activeLocale(locale)"
            @click.native="setLocale(locale)"
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
          <i class="fa fa-at" />
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
        <Btn :inline="true" variant="link" @click.native="openSupportModal">
          {{ $t("labels.supportUs") }}
          <i class="fa fa-heart" />
        </Btn>
      </div>
      <div class="app-footer-item">
        <p>
          <span>Copyright &copy; {{ new Date().getFullYear() }}</span>
          {{ copyrightOwner }}
        </p>
        <p class="rsi-disclaimer">
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
      <div class="app-community-logo">
        <CommunityLogo />
      </div>
      <div class="app-version">
        {{ codename }} ({{ version }})
        <span
          :class="{
            online: online,
          }"
          class="git-revision"
        >
          <span class="hidden">{{ gitRevision }}</span>
          <i class="far fa-fingerprint" />
        </span>
      </div>
      <div class="sc-data-version">
        {{ $t("labels.scDataVersion") }}: {{ scDataVersion }}
      </div>
    </div>
  </footer>
</template>

<script lang="ts">
import Vue from "vue";
import { Component } from "vue-property-decorator";
import { Getter, Mutation } from "vuex-class";
import Btn from "@/frontend/core/components/Btn/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import CommunityLogo from "@/frontend/core/components/CommunityLogo/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

const { availableLocales } = useI18n();

@Component<AppFooter>({
  components: {
    Btn,
    BtnDropdown,
    CommunityLogo,
  },
})
export default class AppFooter extends Vue {
  @Getter("online") online: boolean;

  @Getter("version", { namespace: "app" }) version: string;

  @Getter("codename", { namespace: "app" }) codename: string;

  @Getter("gitRevision", { namespace: "app" }) gitRevision: string;

  @Getter("locale") currentLocale;

  @Mutation("setLocale") setLocale;

  localeMapping = {
    de: "Deutsch",
    en: "English",
    es: "Español",
    fr: "Français",
    it: "Italiano",
    zh: "中文",
    "zh-CN": "中文 (简体)",
    "zh-TW": "中文 (繁體)",
  };

  get copyrightOwner() {
    return window.COPYRIGHT_OWNER;
  }

  get scDataVersion() {
    return window.SC_DATA_VERSION;
  }

  get locales() {
    return availableLocales;
  }

  activeLocale(locale: string) {
    return (
      locale === this.currentLocale ||
      (!locale.includes("zh") && locale === this.currentLocale.split("-")[0])
    );
  }

  openSupportModal() {
    this.$comlink.$emit("open-modal", {
      component: () => import("@/frontend/components/Support/Modal/index.vue"),
      wide: true,
    });
  }
}
</script>
