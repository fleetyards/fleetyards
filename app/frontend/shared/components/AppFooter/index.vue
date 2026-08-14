<script lang="ts">
export default {
  name: "AppFooter",
};
</script>

<script lang="ts" setup>
import CommunityLogo from "@/shared/components/CommunityLogo/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

// Declared, at last. All three apps - frontend, admin and docs - have always
// passed these; the component read `@/frontend/stores/app` instead, so the bound
// values landed on the root <footer> as DOM attributes and were ignored, and a
// shared component reached into one specific app for its state. Admin and docs
// also passed `revision`, which was never the store's key either.
type Props = {
  version?: string;
  codename?: string;
  gitRevision?: string;
  online?: boolean;
};

withDefaults(defineProps<Props>(), {
  version: undefined,
  codename: undefined,
  gitRevision: undefined,
  online: false,
});

const { t } = useI18n();

const copyrightOwner = computed(() => {
  return window.COPYRIGHT_OWNER;
});

const scDataVersion = computed(() => {
  return window.SC_DATA_VERSION;
});

// Was `new Date().getFullYear()` inline in the template, so it was recomputed on
// every render and could not be frozen by a test.
const currentYear = computed(() => new Date().getFullYear());
</script>

<template>
  <footer class="app-footer" data-test="app-footer">
    <div class="app-footer__inner">
      <div class="app-footer__logo">
        <CommunityLogo />
      </div>

      <div class="app-footer__main">
        <!-- Collapsed when empty: admin and docs pass no links, and the row
             still occupied its gap. -->
        <div v-if="$slots.default" class="app-footer__links">
          <slot />
        </div>

        <div v-if="$slots.actions" class="app-footer__actions">
          <slot name="actions" />
        </div>

        <div class="app-footer__disclaimer">
          <p>
            <span>Copyright &copy; {{ currentYear }}</span>
            {{ copyrightOwner }}
          </p>
          <p class="app-footer__disclaimer-rsi">
            This is an unofficial Star Citizen fansite, not affiliated with the
            Cloud Imperium group of companies. All content on this site not
            authored by its host or users are property of their respective
            owners. Star Citizen®, Squadron 42®, Roberts Space Industries®, and
            Cloud Imperium® are registered trademarks of Cloud Imperium Rights
            LLC. All rights reserved.
          </p>
        </div>
      </div>

      <div class="app-footer__social" data-test="app-footer-social">
        <a
          v-tooltip="'Discord'"
          href="https://discord.gg/6EQKAsb"
          target="_blank"
          rel="noopener"
          aria-label="Discord"
        >
          <i class="fa-brands fa-discord" />
        </a>
        <a
          v-tooltip="'Github'"
          href="https://github.com/fleetyards"
          target="_blank"
          rel="noopener"
          aria-label="Github"
        >
          <i class="fa-brands fa-github" />
        </a>
        <a
          v-tooltip="'Bluesky'"
          href="https://bsky.app/profile/fleetyards.net"
          target="_blank"
          rel="noopener"
          aria-label="Bluesky"
        >
          <i class="fa-brands fa-bluesky" />
        </a>
        <a
          v-tooltip="'Instagram'"
          href="https://www.instagram.com/fleetyardsnet/"
          target="_blank"
          rel="noopener"
          aria-label="Instagram"
        >
          <i class="fa-brands fa-instagram" />
        </a>
      </div>

      <div class="app-footer__meta">
        <div class="app-footer__version" data-test="app-footer-version">
          {{ codename }} ({{ version }})
          <!-- The revision was a display:none span behind a tooltip, so it was
               hidden from assistive tech as well and reachable by hover alone. -->
          <span
            :class="{ 'app-footer__revision--online': online }"
            class="app-footer__revision"
          >
            <i class="fa-regular fa-fingerprint" />
            <span class="app-footer__revision-value">{{ gitRevision }}</span>
          </span>
        </div>

        <div class="app-footer__data-version">
          {{ t("labels.scDataVersion") }}: {{ scDataVersion }}
        </div>
      </div>
    </div>
  </footer>
</template>

<!--
  Plain CSS, not lang="scss", for the reason Btn documents: sass preprocesses the
  block first and @apply/@reference reach the minifier as unknown at-rules.
-->
<style scoped>
@reference "../../../entrypoints/tailwind.css";

/*
 * One band, one border, one pair of caps.
 *
 * What this replaces drew its top edge out of five elements: an outer pair of
 * 80px stubs and a full-width inner bar inset 40px, in $panel-outer-border and
 * #444 - the two values the panel redesign retired. It was the same end-cap motif
 * built by hand with fixed insets, and at page width the fixed inset fails in the
 * opposite direction from a narrow panel: 80px is 8% of a 992px viewport and 3%
 * of a 2560px one, so the ticks read as artefacts rather than as a signature.
 *
 * See docs/exec-plans/footer-redesign.md.
 */
.app-footer {
  @apply text-text relative border-t-2;
  background-color: var(--color-surface, rgb(39 43 48 / 0.9));
  border-top-color: var(--color-edge, rgb(122 130 136 / 0.5));
  /* 500ms deliberately, and the only 500ms left in the redesigned components:
     this is the page sliding aside for the off-canvas nav, which `.main` in
     shared/layout.scss animates at the same duration. The 150ms the redesign
     standardised on is for controls answering a pointer. */
  transition: transform 500ms ease;
}

/*
 * Top edge only - the footer's bottom is the end of the document, so there is no
 * edge there for a cap to signature. Geometry from the shared --cap-* tokens, so
 * this cap and a panel's are one motif rather than two that drifted. The var()
 * fallbacks follow Panel and Btn; every layout that renders this footer does load
 * tailwind.css, so here they are consistency rather than necessity.
 */
.app-footer::before {
  content: "";
  @apply absolute z-[1];
  left: max(10px, var(--cap-inset, 12%));
  right: max(10px, var(--cap-inset, 12%));
  top: -2px;
  height: var(--cap-h, 4px);
  background-color: var(--color-endcap, #7a8288);
  border-radius: 0 0 var(--cap-r, 3px) var(--cap-r, 3px);
}

/*
 * A real layout. The four corner regions were `position: absolute` over a
 * centred block flow, with nothing relating the two - so the disclaimer had no
 * reserved space and could run under them - and the whole mobile media query
 * existed to reset those positions one by one.
 */
.app-footer__inner {
  @apply grid items-start gap-5 px-6 py-8 text-center;
  /* auto, not a fixed 100px: the side columns size to the logo and to four
     30px social icons with their gaps, which a fixed track would overflow. */
  grid-template-columns: auto 1fr auto;
  grid-template-areas:
    "logo main social"
    "meta meta meta";
}

.app-footer a {
  @apply text-text cursor-pointer no-underline;
}

.app-footer a:hover {
  @apply text-white;
}

.app-footer__logo {
  @apply flex h-[100px] w-[100px] items-center justify-center opacity-70;
  grid-area: logo;
}

.app-footer__logo :deep(img) {
  @apply max-h-full max-w-full;
}

.app-footer__main {
  @apply flex flex-col items-center gap-4;
  grid-area: main;
}

.app-footer__links {
  @apply flex flex-wrap items-center justify-center gap-x-4 gap-y-2;
}

.app-footer__social {
  @apply flex items-start justify-end gap-4 text-3xl;
  grid-area: social;
}

.app-footer__disclaimer {
  @apply max-w-[70ch];
}

.app-footer__disclaimer p {
  @apply mb-2;
}

/* Was darken($text-color, 20%) - one of the two hand-mixed greys this file used
   in place of the token set. */
.app-footer__disclaimer-rsi {
  @apply text-sm;
  color: var(--color-muted, #7a8288);
}

.app-footer__meta {
  @apply flex flex-wrap items-center justify-between gap-2 text-sm;
  grid-area: meta;
}

.app-footer__data-version {
  color: var(--color-gray-light, #7a8288);
}

.app-footer__revision {
  @apply inline-flex items-center gap-1;
  /* Offline is not signalled by opacity alone: the value goes muted and the
     fingerprint dims with it. */
  color: var(--color-muted, #7a8288);
}

.app-footer__revision--online {
  @apply text-text;
}

.app-footer__revision-value {
  @apply font-mono text-xs;
}

/*
 * The nav offset, on one token instead of a copied number. 300px appears four
 * times in partials/app-navigation.scss and twice more in shared/layout.scss;
 * the footer at least stops adding to that. Translate rather than left/right, so
 * the slide runs on the compositor.
 */
@media (max-width: 992px) {
  .app-footer__inner {
    @apply px-4;
    grid-template-columns: 1fr;
    grid-template-areas:
      "logo"
      "social"
      "main"
      "meta";
    padding-right: max(1rem, env(safe-area-inset-right));
    padding-left: max(1rem, env(safe-area-inset-left));
  }

  .app-footer__logo {
    @apply w-full;
  }

  .app-footer__social {
    @apply justify-center;
  }

  .app-footer__meta {
    @apply justify-center text-center;
  }

  .nav-visible .app-footer {
    transform: translateX(calc(-1 * var(--nav-width, 300px)));
  }
}

@media (prefers-reduced-motion: reduce) {
  .app-footer {
    transition-duration: 1ms;
  }
}
</style>
