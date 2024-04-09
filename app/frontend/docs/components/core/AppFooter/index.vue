<template>
  <footer
    class="relative left-0 pt-1 text-center transition-nav duration-500 ease-[ease]"
  >
    <div class="absolute right-0 left-0 top-0 app-footer-border-top">
      <div
        class="absolute block w-[80px] h-0.5 left-0 top-0 border-t-2 border-panel-borderOuter"
      />
      <div
        class="absolute block w-[80px] h-0.5 right-0 top-0 border-t-2 border-panel-borderOuter"
      />
    </div>
    <div
      class="relative py-[30px] bg-brand-grayBg/70 border-t-3 border-panel-borderInner/90"
    >
      <div class="absolute w-full h-[3px] px-[40px] -top-[3px]">
        <div class="w-full h-[3px] bg-panel-borderInnerOverlay" />
      </div>
      <div class="mb-3 flex justify-center items-center gap-1 flex-wrap">
        <a
          v-tooltip="'Roberts Space Industries'"
          href="https://robertsspaceindustries.com/"
          target="_blank"
          rel="noopener"
        >
          RSI
        </a>
        |
        <a
          target="_blank"
          rel="noopener"
          href="https://fleetyards.net/privacy-policy"
        >
          {{ t("nav.privacyPolicy") }}
        </a>
        |
        <a
          target="_blank"
          rel="noopener"
          href="https://fleetyards.net/impressum"
        >
          {{ t("nav.impressum") }}
        </a>
      </div>
      <div
        class="gap-4 flex justify-center mb-1 text-[180%] lg:absolute lg:top-[10px] lg:right-[25px]"
      >
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
        <a
          v-tooltip="'Twitter'"
          href="https://twitter.com/FleetYardsNet"
          target="_blank"
          rel="noopener"
          aria-label="Twitter"
        >
          <i class="fab fa-twitter" />
        </a>
      </div>
      <div class="app-footer-support">
        <Btn :inline="true" variant="link" @click="openSupportModal">
          {{ t("labels.supportUs") }}
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
        <span class="git-revision">
          <span class="hidden">{{ gitRevision }}</span>
          <i class="far fa-fingerprint" />
        </span>
      </div>
      <div class="sc-data-version">
        {{ t("labels.scDataVersion") }}: {{ scDataVersion }}
      </div>
    </div>
  </footer>
</template>

<script lang="ts" setup>
import Btn from "@/docs/components/core/Btn/index.vue";
import { useI18n } from "@/docs/composables/useI18n";
import CommunityLogo from "@/shared/components/CommunityLogo/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();

const gitRevision = computed(() => window.GIT_REVISION);

const version = computed(() => window.APP_VERSION);

const codename = computed(() => window.APP_CODENAME);

const copyrightOwner = computed(() => window.COPYRIGHT_OWNER);

const scDataVersion = computed(() => window.SC_DATA_VERSION);

const comlink = useComlink();

const openSupportModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/SupportBtn/Modal/index.vue"),
    wide: true,
  });
};
</script>

<script lang="ts">
export default {
  name: "AppFooter",
};
</script>

<style lang="scss" scoped>
$footerInnerBorderWidth: 3px;
$footerOuterBorderWidth: 2px;

.app-footer {
  .git-revision {
    cursor: pointer;
    opacity: 0.5;

    &.online {
      opacity: 1;
    }

    .hidden {
      display: none;
    }
  }

  a {
    color: $text-color;
    cursor: pointer;

    &:hover {
      color: white;
    }
  }

  .app-footer-support {
    margin: 30px 0;
  }

  .app-community-logo {
    position: absolute;
    top: 10px;
    left: 25px;
    width: 100px;
    height: 100px;
    opacity: 0.7;

    img {
      max-width: 100%;
      max-height: 100%;
    }
  }

  .rsi-disclaimer {
    color: darken($text-color, 20%);
  }

  .app-version {
    position: absolute;
    bottom: 15px;
    left: 15px;
  }

  .sc-data-version {
    position: absolute;
    right: 15px;
    bottom: 15px;
    color: darken($text-color, 40%);
  }
}

@media (max-width: $desktop-breakpoint) {
  .app-footer {
    right: 0;
    left: auto;

    .app-community-logo {
      position: relative;
      top: auto;
      left: auto;
      width: 100%;
      margin-bottom: 10px;
      background-size: 100px;
    }

    .app-footer-support {
      margin: 15px 0;
    }

    .app-footer-inner {
      padding-right: env(safe-area-inset-right);
      padding-left: env(safe-area-inset-left);
    }

    .sc-data-version {
      position: relative;
      right: 0;
      bottom: 0;
      padding-top: 5px;
      padding-bottom: 15px;
      text-align: center;
    }
  }

  .nav-visible {
    .app-footer {
      right: 300px;
    }
  }
}

@media (max-width: 370px) {
  .nav-visible {
    .app-footer {
      right: 250px;
    }
  }
}
</style>
```
