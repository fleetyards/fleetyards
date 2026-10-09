<script lang="ts">
export default {
  name: "FleetHeaderLinks",
};
</script>

<script lang="ts" setup>
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Fleet } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  large?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  large: false,
});

const { t } = useI18n();

type Link = { key: string; icon: string; href: string; label: string };

const external = (
  key: string,
  icon: string,
  label: string,
  url?: string | null,
  prefix = "//",
) => (url ? [{ key, icon, label, href: `${prefix}${url}` }] : []);

// RSI sits second, after the fleet's own homepage, so it is a place in the list
// rather than a link of its own.
const links = computed<(Link | { key: "rsi" })[]>(() => [
  ...external(
    "homepage",
    "fa-light fa-globe globe-rotate",
    t("labels.homepage"),
    props.fleet.homepage,
  ),
  ...(props.fleet.rsiSid ? [{ key: "rsi" as const }] : []),
  ...external(
    "guilded",
    "fa-brands fa-guilded",
    t("labels.guilded"),
    props.fleet.guilded,
  ),
  ...external(
    "discord",
    "fa-brands fa-discord",
    t("labels.discord"),
    props.fleet.discord,
  ),
  ...external(
    "ts",
    "fa-brands fa-teamspeak",
    t("labels.fleet.ts"),
    props.fleet.ts,
    "",
  ),
  ...external(
    "youtube",
    "fa-brands fa-youtube",
    t("labels.youtube"),
    props.fleet.youtube,
  ),
  ...external(
    "twitch",
    "fa-brands fa-twitch",
    t("labels.twitch"),
    props.fleet.twitch,
  ),
]);
</script>

<template>
  <div>
    <template v-for="link in links" :key="link.key">
      <RsiProfileLink
        v-if="!('href' in link)"
        :sid="fleet.rsiSid!"
        :verified="fleet.rsiVerified"
        icon-only
        :large="large"
      />
      <a
        v-else
        v-tooltip="link.label"
        :aria-label="link.label"
        :href="link.href"
        target="_blank"
        rel="noopener"
      >
        <i :class="link.icon" />
      </a>
    </template>
  </div>
</template>
