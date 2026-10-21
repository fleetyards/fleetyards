<script lang="ts">
export default {
  name: "HomeLandingFeatures",
};
</script>

<script lang="ts" setup>
import { RouterLink, type RouteLocationRaw } from "vue-router";
import {
  useElementHover,
  useElementVisibility,
  useFocusWithin,
  usePreferredReducedMotion,
} from "@vueuse/core";
import Panel from "@/shared/components/base/Panel/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import hangarImage from "@/images/home-feature-hangar.webp";
import fleetsImage from "@/images/bg-8.webp";
import shipsImage from "@/images/home-feature-ships.webp";
import compareImage from "@/images/home-feature-compare.webp";
import cargoImage from "@/images/home-feature-cargo.webp";
import tradeImage from "@/images/home-feature-trade.webp";

const { t } = useI18n();

type Tab = {
  key: string;
  icon: string;
  open: boolean;
  to?: RouteLocationRaw;
  href?: string;
  image?: string;
  imagePosition?: string;
  items: { key: string; icon: string; to?: RouteLocationRaw }[];
};

const tabs: Tab[] = [
  {
    key: "hangar",
    icon: "fa-duotone fa-warehouse",
    open: false,
    to: { name: "hangar-preview" },
    image: hangarImage,
    imagePosition: "center 40%",
    items: [
      { key: "sync", icon: "fa-duotone fa-rotate" },
      { key: "paints", icon: "fa-duotone fa-paintbrush" },
      { key: "loadouts", icon: "fa-duotone fa-sliders" },
      { key: "fleetchart", icon: "fa-duotone fa-ruler-horizontal" },
      { key: "log", icon: "fa-duotone fa-book" },
      { key: "share", icon: "fa-duotone fa-star" },
    ],
  },
  {
    key: "fleets",
    icon: "fa-duotone fa-users",
    open: false,
    to: { name: "fleet-preview" },
    image: fleetsImage,
    imagePosition: "center top",
    items: [
      { key: "members", icon: "fa-duotone fa-users" },
      { key: "squadrons", icon: "fa-duotone fa-people-group" },
      { key: "maps", icon: "fa-duotone fa-globe" },
      { key: "ships", icon: "fa-duotone fa-rocket" },
      { key: "allies", icon: "fa-duotone fa-handshake" },
      { key: "discord", icon: "fa-brands fa-discord" },
    ],
  },
  {
    key: "ships",
    icon: "fa-duotone fa-rocket-launch",
    open: true,
    to: { name: "ships" },
    image: shipsImage,
    imagePosition: "center 45%",
    items: [
      { key: "ships", icon: "fa-duotone fa-rocket-launch" },
      { key: "viewer", icon: "fa-duotone fa-cube" },
      { key: "patches", icon: "fa-duotone fa-code-branch" },
      { key: "components", icon: "fa-duotone fa-microchip" },
      { key: "locations", icon: "fa-duotone fa-planet-ringed" },
      { key: "crafting", icon: "fa-duotone fa-hammer" },
    ],
  },
  {
    key: "tools",
    icon: "fa-duotone fa-toolbox",
    open: true,
    to: { name: "tools" },
    items: [
      {
        key: "compare",
        icon: "fa-duotone fa-code-compare",
        to: { name: "compare" },
      },
      {
        key: "cargo",
        icon: "fa-duotone fa-grid-2",
        to: { name: "cargo-grids" },
      },
      {
        key: "trade",
        icon: "fa-duotone fa-route",
        to: { name: "trade-routes" },
      },
      {
        key: "travel",
        icon: "fa-duotone fa-stopwatch",
        to: { name: "travel-times" },
      },
      { key: "tours", icon: "fa-duotone fa-map-location-dot" },
      { key: "stats", icon: "fa-duotone fa-chart-bar", to: { name: "stats" } },
    ],
  },
  {
    key: "developers",
    icon: "fa-duotone fa-code",
    open: true,
    href: "https://api.fleetyards.net",
    items: [
      { key: "api", icon: "fa-duotone fa-code" },
      { key: "oauth", icon: "fa-duotone fa-right-to-bracket" },
      { key: "embed", icon: "fa-duotone fa-window-restore" },
      { key: "discord", icon: "fa-brands fa-discord" },
      { key: "app", icon: "fa-duotone fa-mobile" },
      { key: "media", icon: "fa-duotone fa-images" },
    ],
  },
];

const toolShots = [
  {
    key: "compare",
    icon: "fa-light fa-code-compare",
    image: compareImage,
    to: { name: "compare" },
  },
  {
    key: "cargo",
    icon: "fa-light fa-grid-2",
    image: cargoImage,
    to: { name: "cargo-grids" },
  },
  {
    key: "trade",
    icon: "fa-light fa-route",
    image: tradeImage,
    to: { name: "trade-routes" },
  },
];

const activeKey = ref(tabs[0].key);

const tabRefs = ref<HTMLButtonElement[]>([]);

const root = useTemplateRef<HTMLElement>("root");

// Rotation runs off the progress bar's animationend, so pausing the bar
// pauses the timer with it.
const rotating = ref(usePreferredReducedMotion().value !== "reduce");

const hovered = useElementHover(root);
const { focused } = useFocusWithin(root);
const visible = useElementVisibility(root, { threshold: 0.5 });

const rotationPaused = computed(
  () => hovered.value || focused.value || !visible.value,
);

const advance = () => {
  const index = tabs.findIndex((tab) => tab.key === activeKey.value);
  activeKey.value = tabs[(index + 1) % tabs.length].key;
};

const select = (key: string) => {
  rotating.value = false;
  activeKey.value = key;
};

const focusTab = (index: number) => {
  const nextIndex = (index + tabs.length) % tabs.length;
  select(tabs[nextIndex].key);
  tabRefs.value[nextIndex]?.focus();
};

const onKeydown = (event: KeyboardEvent, index: number) => {
  if (event.key === "ArrowDown" || event.key === "ArrowRight") {
    event.preventDefault();
    focusTab(index + 1);
  } else if (event.key === "ArrowUp" || event.key === "ArrowLeft") {
    event.preventDefault();
    focusTab(index - 1);
  } else if (event.key === "Home") {
    event.preventDefault();
    focusTab(0);
  } else if (event.key === "End") {
    event.preventDefault();
    focusTab(tabs.length - 1);
  }
};
</script>

<template>
  <div ref="root" class="home-landing-features">
    <div
      class="home-landing-features__tabs"
      role="tablist"
      aria-orientation="vertical"
    >
      <button
        v-for="(tab, index) in tabs"
        :id="`home-features-tab-${tab.key}`"
        :key="tab.key"
        ref="tabRefs"
        type="button"
        role="tab"
        class="home-landing-features__tab"
        :class="{
          'home-landing-features__tab--active': tab.key === activeKey,
        }"
        :aria-selected="tab.key === activeKey"
        :aria-controls="`home-features-panel-${tab.key}`"
        :tabindex="tab.key === activeKey ? 0 : -1"
        @click="select(tab.key)"
        @keydown="onKeydown($event, index)"
      >
        <i :class="tab.icon" aria-hidden="true" />
        <span class="home-landing-features__tab-text">
          <span class="home-landing-features__tab-label">
            {{ t(`home.landing.features.${tab.key}.label`) }}
          </span>
          <span class="home-landing-features__tab-hint">
            {{ t(`home.landing.features.${tab.key}.hint`) }}
          </span>
        </span>
        <span
          v-if="rotating && tab.key === activeKey"
          :key="activeKey"
          class="home-landing-features__progress"
          :class="{
            'home-landing-features__progress--paused': rotationPaused,
          }"
          aria-hidden="true"
          @animationend="advance"
        />
      </button>
    </div>
    <Panel class="home-landing-features__stage" :outer-spacing="false">
      <div class="home-landing-features__panes">
        <div
          v-for="tab in tabs"
          :id="`home-features-panel-${tab.key}`"
          :key="tab.key"
          role="tabpanel"
          class="home-landing-features__pane"
          :class="{
            'home-landing-features__pane--active': tab.key === activeKey,
          }"
          :aria-labelledby="`home-features-tab-${tab.key}`"
          :inert="tab.key !== activeKey"
        >
          <div
            v-if="tab.image"
            class="home-landing-features__visual home-landing-features__visual--image"
          >
            <img
              :src="tab.image"
              :style="{ objectPosition: tab.imagePosition }"
              alt=""
              loading="lazy"
            />
          </div>
          <div
            v-else-if="tab.key === 'tools'"
            class="home-landing-features__visual home-landing-features__shots"
          >
            <RouterLink
              v-for="shot in toolShots"
              :key="shot.key"
              :to="shot.to"
              class="home-landing-features__shot"
            >
              <img :src="shot.image" alt="" loading="lazy" />
              <span class="home-landing-features__shot-label">
                <i :class="shot.icon" aria-hidden="true" />
                {{ t(`home.landing.features.tools.items.${shot.key}.title`) }}
              </span>
            </RouterLink>
          </div>
          <div
            v-else
            class="home-landing-features__visual home-landing-features__developers"
            aria-hidden="true"
          >
            <pre
              class="home-landing-features__code"
            ><span class="home-landing-features__code-comment"># {{ t("home.landing.features.developers.codeComment") }}</span>
GET https://api.fleetyards.net/v1/models/rsi-perseus

{
  <span class="home-landing-features__code-key">"name"</span>: <span class="home-landing-features__code-string">"Perseus"</span>,
  <span class="home-landing-features__code-key">"manufacturer"</span>: { <span class="home-landing-features__code-key">"name"</span>: <span class="home-landing-features__code-string">"Roberts Space Industries"</span> },
  <span class="home-landing-features__code-key">"focus"</span>: <span class="home-landing-features__code-string">"Heavy Gunship"</span>,
  …
}</pre>
            <div class="home-landing-features__developers-side">
              <div class="home-landing-features__embed">
                <span class="home-landing-features__embed-title">
                  <i class="fa-light fa-window-restore" />
                  {{ t("home.landing.features.developers.items.embed.title") }}
                </span>
                <span class="home-landing-features__embed-grid">
                  <span v-for="cell in 6" :key="cell" />
                </span>
              </div>
              <span class="home-landing-features__sign-in">
                <i class="fa-light fa-right-to-bracket" />
                {{ t("home.landing.features.developers.signIn") }}
              </span>
            </div>
          </div>
          <div class="home-landing-features__body">
            <div class="home-landing-features__head">
              <div>
                <span class="home-landing-features__micro">
                  {{
                    t(
                      tab.open
                        ? "home.landing.features.openToEveryone"
                        : "home.landing.features.withAccount",
                    )
                  }}
                </span>
                <h3 class="home-landing-features__title">
                  {{ t(`home.landing.features.${tab.key}.title`) }}
                </h3>
              </div>
              <Btn :to="tab.to" :href="tab.href" :size="BtnSizesEnum.MD">
                <i :class="tab.icon" />
                {{ t(`home.landing.features.${tab.key}.action`) }}
              </Btn>
            </div>
            <ul class="home-landing-features__items">
              <li
                v-for="item in tab.items"
                :key="item.key"
                class="home-landing-features__item"
              >
                <component
                  :is="item.to ? RouterLink : 'div'"
                  :to="item.to"
                  class="home-landing-features__item-inner"
                  :class="{
                    'home-landing-features__item-inner--link': item.to,
                  }"
                >
                  <i :class="item.icon" aria-hidden="true" />
                  <div>
                    <span class="home-landing-features__item-title">
                      {{
                        t(
                          `home.landing.features.${tab.key}.items.${item.key}.title`,
                        )
                      }}
                    </span>
                    <p>
                      {{
                        t(
                          `home.landing.features.${tab.key}.items.${item.key}.text`,
                        )
                      }}
                    </p>
                  </div>
                </component>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.home-landing-features {
  display: grid;
  grid-template-columns: 280px minmax(0, 1fr);
  gap: 16px;
  margin-top: 16px;
}

.home-landing-features__tabs {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.home-landing-features__tab {
  position: relative;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  color: var(--color-text);
  text-align: left;
  cursor: pointer;
  background: none;
  border: 1px solid transparent;
  border-radius: var(--radius-surface-slim);
  transition:
    background-color 0.2s ease,
    border-color 0.2s ease;

  i {
    width: 24px;
    font-size: 20px;
    color: var(--color-muted);
    text-align: center;
  }

  &:hover {
    border-color: var(--color-edge-soft);
  }

  &:focus-visible {
    outline: 2px solid var(--color-edge);
    outline-offset: 2px;
  }
}

.home-landing-features__tab--active {
  background: var(--color-control);
  border-color: var(--color-edge);

  .home-landing-features__tab-label {
    color: var(--color-lifted);
  }
}

.home-landing-features__progress {
  position: absolute;
  top: 10px;
  bottom: 10px;
  left: -1px;
  width: 4px;
  overflow: hidden;
  background: var(--color-edge-soft);
  border-radius: 0 2px 2px 0;

  &::after {
    position: absolute;
    inset: 0;
    content: "";
    background: var(--color-primary);
    transform-origin: top;
    animation: home-landing-features-progress 7s linear forwards;
    animation-play-state: inherit;
  }
}

.home-landing-features__progress--paused,
.home-landing-features__progress--paused::after {
  animation-play-state: paused;
}

@keyframes home-landing-features-progress {
  from {
    transform: scaleY(0);
  }

  to {
    transform: scaleY(1);
  }
}

.home-landing-features__tab-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.home-landing-features__tab-label {
  font-size: 15px;
  font-weight: 600;
}

.home-landing-features__tab-hint {
  font-size: 12.5px;
  color: var(--color-text-dim);
}

.home-landing-features__stage {
  overflow: hidden;
}

.home-landing-features__panes {
  display: grid;
}

.home-landing-features__pane {
  grid-area: 1 / 1;
  visibility: hidden;
  opacity: 0;
  transition:
    opacity 0.15s ease,
    visibility 0s linear 0.15s;
}

.home-landing-features__pane--active {
  visibility: visible;
  opacity: 1;
  transition: opacity 0.15s ease;
}

.home-landing-features__visual {
  height: 280px;
  border-bottom: 1px solid var(--color-edge-soft);
}

.home-landing-features__visual--image img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.home-landing-features__shots {
  display: grid;
  grid-template-rows: 1.55fr 1fr;
  grid-template-columns: 1.35fr 1fr;
  gap: 12px;
  padding: 16px;
  box-sizing: border-box;
  background: #0a0e13;
}

.home-landing-features__shot {
  position: relative;
  display: block;
  overflow: hidden;
  border: 1px solid var(--color-edge-soft);
  border-radius: 8px;
  transition: border-color 0.2s ease;

  &:hover,
  &:focus-visible {
    border-color: var(--color-edge);
  }

  &:first-child {
    grid-row: span 2;
  }

  img {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: left top;
  }

  &:nth-child(2) img {
    object-position: center 40%;
  }

  &:nth-child(3) img {
    object-position: left center;
  }
}

.home-landing-features__shot-label {
  position: absolute;
  bottom: 10px;
  left: 10px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 9px;
  font-size: 12px;
  color: var(--color-lifted);
  background: rgb(10 14 19 / 80%);
  border: 1px solid var(--color-edge-soft);
  border-radius: 999px;

  i {
    color: var(--color-muted);
  }
}

.home-landing-features__developers {
  display: flex;
  gap: 14px;
  padding: 22px 26px;
  box-sizing: border-box;
  background: linear-gradient(180deg, #0d1218, #121a24);
}

.home-landing-features__code {
  flex: 1.3;
  min-width: 0;
  margin: 0;
  padding: 16px 18px;
  overflow: hidden;
  font:
    12.5px/19px ui-monospace,
    Menlo,
    monospace;
  color: var(--color-text);
  white-space: pre;
  background: rgb(5 7 12 / 75%);
  border: 1px solid var(--color-edge-soft);
  border-radius: 10px;
}

.home-landing-features__code-comment {
  color: var(--color-muted);
}

.home-landing-features__code-key {
  color: #8fb8de;
}

.home-landing-features__code-string {
  color: #a9c98a;
}

.home-landing-features__developers-side {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 12px;
}

.home-landing-features__embed {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 10px;
  padding: 12px 14px;
  background: rgb(39 43 48 / 60%);
  border: 1px solid var(--color-edge-soft);
  border-radius: 10px;
}

.home-landing-features__embed-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-lifted);

  i {
    color: var(--color-muted);
  }
}

.home-landing-features__embed-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;

  span {
    height: 34px;
    background: rgb(122 130 136 / 20%);
    border-radius: 4px;
  }
}

.home-landing-features__sign-in {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px;
  font-size: 13px;
  color: var(--color-lifted);
  background: var(--color-control);
  border: 1px solid var(--color-edge);
  border-radius: 8px;
}

.home-landing-features__body {
  display: flex;
  flex-direction: column;
  gap: 18px;
  padding: 22px 26px 26px;
}

.home-landing-features__head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 24px;
}

.home-landing-features__micro {
  font-family: Orbitron, sans-serif;
  font-size: 10px;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.16em;
}

.home-landing-features__title {
  margin: 4px 0 0;
  font-family: Orbitron, sans-serif;
  font-size: 24px;
  font-weight: 400;
  color: var(--color-lifted);
}

.home-landing-features__items {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px 24px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.home-landing-features__item-inner {
  display: flex;
  gap: 12px;

  i {
    margin-top: 2px;
    font-size: 18px;
    color: var(--color-muted);
  }

  p {
    margin: 0;
    font-size: 13px;
    line-height: 18px;
    color: var(--color-text-dim);
  }
}

.home-landing-features__item-inner--link {
  margin: -8px -10px;
  padding: 8px 10px;
  color: inherit;
  text-decoration: none;
  border-radius: 8px;
  transition: background-color 0.2s ease;

  &:hover,
  &:focus-visible {
    color: inherit;
    text-decoration: none;
    background: var(--color-control);
  }

  &:hover .home-landing-features__item-title {
    text-decoration: underline;
  }
}

.home-landing-features__item-title {
  display: block;
  margin-bottom: 3px;
  font-size: 14px;
  font-weight: 600;
  color: var(--color-lifted);
}

@media (max-width: 991px) {
  .home-landing-features {
    grid-template-columns: minmax(0, 1fr);
  }

  .home-landing-features__tabs {
    flex-direction: row;
    overflow-x: auto;
  }

  .home-landing-features__tab {
    flex: 0 0 auto;
  }

  .home-landing-features__tab-hint {
    display: none;
  }

  .home-landing-features__items {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 575px) {
  .home-landing-features__visual {
    height: 180px;
  }

  .home-landing-features__shots {
    grid-template-rows: minmax(0, 1fr);
    grid-template-columns: minmax(0, 1fr);
    height: 200px;
  }

  .home-landing-features__shot:not(:first-child),
  .home-landing-features__developers-side {
    display: none;
  }

  .home-landing-features__head {
    flex-direction: column;
    align-items: flex-start;
  }

  .home-landing-features__items {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
