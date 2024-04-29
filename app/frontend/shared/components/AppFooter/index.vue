<script lang="ts">
export default {
  name: "AppFooter",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import CommunityLogo from "@/shared/components/CommunityLogo/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppStore } from "@/frontend/stores/app";
import { storeToRefs } from "pinia";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";

const { t } = useI18n();

const appStore = useAppStore();

const { online, version, codename, gitRevision } = storeToRefs(appStore);

const copyrightOwner = computed(() => {
  return window.COPYRIGHT_OWNER;
});

const scDataVersion = computed(() => {
  return window.SC_DATA_VERSION;
});

const comlink = useComlink();

const openSupportModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/SupportBtn/Modal/index.vue"),
    wide: true,
  });
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
        <slot />
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
