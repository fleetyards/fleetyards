<script lang="ts">
export default {
  name: "FleetShow",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  FeatureFlagName,
  useFleetSquadrons,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership?: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { isFleetFeatureEnabled } = useFeatures();

/*
 * The fleet's own front page is where somebody meets it, so its sub-units
 * belong here rather than only behind a tab. Gated the way the tab is: the
 * flag, and a role that may read them.
 */
const showSquadrons = computed(
  () =>
    isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_SQUADRONS) &&
    (props.membership?.capabilities?.readSquadrons ?? false),
);

const { data: squadrons } = useFleetSquadrons(
  computed(() => props.fleet.slug),
  {},
  { query: { enabled: showSquadrons } },
);

const squadronList = computed(() => squadrons.value?.items ?? []);

const description = computed(() => {
  if (!props.fleet || !props.fleet.description) {
    return undefined;
  }

  return props.fleet.description.replaceAll("\n", "<br>");
});
</script>

<template>
  <div class="row">
    <div class="col-12">
      <h1 class="large heading">
        <Avatar
          v-if="fleet.logo"
          :avatar="fleet.logo.smallUrl"
          :transparent="!!fleet.logo"
          :round="false"
          size="large"
          icon="fa-duotone fa-image"
        />
        <span class="title">{{ fleet.name }} ({{ fleet.fid }})</span>
      </h1>
    </div>
  </div>
  <div class="row">
    <div class="col-12 links">
      <a
        v-if="fleet.homepage"
        v-tooltip="t('labels.homepage')"
        :aria-label="t('labels.homepage')"
        :href="`//${fleet.homepage}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-light fa-globe globe-rotate" />
      </a>
      <a
        v-if="fleet.rsiSid"
        v-tooltip="t('nav.rsiProfile')"
        :aria-label="t('nav.rsiProfile')"
        :href="`https://robertsspaceindustries.com/orgs/${fleet.rsiSid}`"
        target="_blank"
        rel="noopener"
      >
        <i class="icon icon-rsi icon-large" />
      </a>
      <a
        v-if="fleet.guilded"
        v-tooltip="t('labels.guilded')"
        :aria-label="t('labels.guilded')"
        :href="`//${fleet.guilded}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-guilded" />
      </a>
      <a
        v-if="fleet.discord"
        v-tooltip="t('labels.discord')"
        :aria-label="t('labels.discord')"
        :href="`//${fleet.discord}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-discord" />
      </a>
      <a
        v-if="fleet.ts"
        v-tooltip="t('labels.fleet.ts')"
        :aria-label="t('labels.fleet.ts')"
        :href="fleet.ts"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-teamspeak" />
      </a>
      <a
        v-if="fleet.youtube"
        v-tooltip="t('labels.youtube')"
        :aria-label="t('labels.youtube')"
        :href="`//${fleet.youtube}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-youtube" />
      </a>
      <a
        v-if="fleet.twitch"
        v-tooltip="t('labels.twitch')"
        :aria-label="t('labels.twitch')"
        :href="`//${fleet.twitch}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-twitch" />
      </a>
    </div>
  </div>
  <div v-if="squadronList.length" class="row md:justify-center">
    <div class="col-12 col-md-8">
      <Heading :level="HeadingLevelEnum.H2">
        {{ t("headlines.fleets.squadrons.index") }}
      </Heading>
      <div class="squadrons">
        <router-link
          v-for="squadron in squadronList"
          :key="squadron.id"
          class="squadron"
          :to="{
            name: 'fleet-squadron',
            params: { slug: fleet.slug, squadron: squadron.slug },
          }"
          :data-test="`fleet-squadron-${squadron.slug}`"
        >
          <SquadronEmblem :squadron="squadron" :size="32" />
          <span class="squadron-name">{{ squadron.name }}</span>
          <span class="squadron-count text-muted">
            {{
              t("labels.fleet.squadrons.memberCount", {
                count: squadron.memberCount,
              })
            }}
          </span>
        </router-link>
      </div>
    </div>
  </div>

  <div v-if="description" class="row md:justify-center">
    <div class="col-12 col-md-8">
      <p class="description" v-html="description" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.squadrons {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 20px;
}

// A row of links rather than a grid of cards: the front page introduces the
// fleet, and the squadrons page is where they are read properly.
.squadron {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  background-color: var(--color-control, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  color: var(--color-text, #c8c8c8);
  text-decoration: none;
  transition: background-color 150ms ease;

  &:hover,
  &:focus-visible {
    background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
    color: var(--color-text, #c8c8c8);
  }
}

.squadron-count {
  font-size: 0.85em;
}

@import "./index.scss";
</style>
