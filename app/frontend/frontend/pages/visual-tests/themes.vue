<script lang="ts">
export default {
  name: "VisualTestsThemesPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import Slider from "@/shared/components/base/Slider/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import Toggle from "@/shared/components/base/Toggle/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

/*
 * The themes this page puts side by side. `undefined` is the default one, which
 * is not declared anywhere -- it is the fallback literal inside each component's
 * `var()`, so the column with no attribute is the honest way to show it.
 */
const themes: { key: string; label: string; theme?: string }[] = [
  { key: "default", label: "Default (frontend)", theme: undefined },
  { key: "admin", label: "Admin", theme: "admin" },
];

/*
 * Each swatch reads its token the way a component does -- through the fallback,
 * not around it. That is not a convenience: the default theme declares none of
 * these, so a swatch reading the bare `var()` paints nothing in the left column
 * and the page would report the default theme as broken rather than as absent.
 */
const tokens = [
  {
    name: "--color-primary",
    fallback: "#428bca",
    usage: "rails, caps, fills, focus",
  },
  {
    name: "--color-primary-shade",
    fallback: "#245682",
    usage: "glow under a rail",
  },
  {
    name: "--color-primary-shade-soft",
    fallback: "#3071a9",
    usage: "toggle border, on + hover",
  },
  {
    name: "--color-primary-tint",
    fallback: "#92bce0",
    usage: "label on an accent fill",
  },
];

const sliderValue = ref(40);

const toggled = ref(true);
</script>

<template>
  <p>
    Every accent below comes from the same component. Nothing here is a
    duplicate stylesheet or a variant prop &mdash; the two columns differ only
    by a <code>data-theme</code> attribute on the element wrapping them, which
    is what the admin layout sets on <code>&lt;html&gt;</code>.
  </p>

  <Heading :level="HeadingLevelEnum.H2">Tokens</Heading>
  <p>
    The base token lives in <code>entrypoints/tailwind.css</code> so Tailwind
    can emit utilities for it. The three derived tones exist because SCSS
    <code>darken()</code> cannot follow a custom property, so a shade that used
    to be computed at build time is now something a theme declares.
  </p>
  <div class="row">
    <div
      v-for="entry in themes"
      :key="entry.key"
      :data-theme="entry.theme"
      class="col-12 col-md-6"
    >
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H3">{{
          entry.label
        }}</PanelHeading>
        <PanelBody>
          <div v-for="token in tokens" :key="token.name" class="vt-theme-token">
            <span
              class="vt-theme-swatch"
              :style="{ background: `var(${token.name}, ${token.fallback})` }"
            />
            <code>{{ token.name }}</code>
            <BaseText muted no-spacing>{{ token.usage }}</BaseText>
          </div>
        </PanelBody>
      </Panel>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Controls</Heading>
  <p>
    A button carries the accent on its end-cap, which only lights on hover,
    press or focus &mdash; the <code>active</code> row below is the state you
    can see standing still. Hover the neutral row to watch the cap come up in
    the column's own colour.
  </p>
  <div class="row">
    <div
      v-for="entry in themes"
      :key="entry.key"
      :data-theme="entry.theme"
      class="col-12 col-md-6"
    >
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H3">{{
          entry.label
        }}</PanelHeading>
        <PanelBody>
          <div class="vt-row">
            <Btn>Neutral</Btn>
            <Btn class="active">Active</Btn>
            <Btn variant="ghost" class="active">Ghost active</Btn>
            <Btn loading>Loading</Btn>
          </div>

          <div class="vt-row">
            <BtnGroup segmented>
              <Btn class="active">On</Btn>
              <Btn>Off</Btn>
            </BtnGroup>
          </div>

          <div class="vt-row">
            <Chip :state="ChipStatesEnum.INCLUDED" :count="12">Included</Chip>
            <Chip :state="ChipStatesEnum.EXCLUDED" :count="3">Excluded</Chip>
            <Pill>Default</Pill>
            <Pill variant="neutral">Neutral</Pill>
          </div>

          <div class="vt-row">
            <Toggle
              label="themes"
              :active="toggled"
              inline
              @toggle="toggled = !toggled"
            />
            <BaseText muted no-spacing>toggle, on</BaseText>
          </div>

          <Slider v-model="sliderValue" process />
        </PanelBody>
      </Panel>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Loading</Heading>
  <p>
    The loader is where the old admin colour lived, applied through an
    <code>admin</code> prop each call site had to remember to pass &mdash; two
    of the admin's ten did. It reads the token now, so there is no prop and
    nothing to forget.
  </p>
  <div class="row">
    <div
      v-for="entry in themes"
      :key="entry.key"
      :data-theme="entry.theme"
      class="col-12 col-md-6"
    >
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H3">{{
          entry.label
        }}</PanelHeading>
        <PanelBody>
          <div class="vt-theme-loaders">
            <Loader loading relative />
          </div>
          <div class="vt-theme-loaders vt-theme-loaders--small">
            <SmallLoader loading />
          </div>
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.vt-theme-token {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.vt-theme-swatch {
  width: 40px;
  height: 24px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control-bare, 6px);
  flex: 0 0 auto;
}

/*
 * Both loaders position themselves absolutely against the nearest positioned
 * ancestor, so each needs a box of its own to sit in rather than escaping to
 * the page.
 */
.vt-theme-loaders {
  position: relative;
  height: 160px;
}

.vt-theme-loaders--small {
  height: 60px;
}
</style>
