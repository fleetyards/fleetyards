<script lang="ts">
export default {
  name: "FleetHeader",
};
</script>

<script lang="ts" setup>
import LocationName from "@/frontend/components/LocationName/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import FidNotice from "@/frontend/components/Fleets/FidNotice/index.vue";
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Fleet } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // The FID notice is for whoever runs the fleet: verifying it is theirs to do,
  // and the settings pages check the same.
  canManage?: boolean;
  // Logo and name on one line above the links, for a page whose content is
  // below it rather than the fleet itself.
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  canManage: false,
  compact: false,
});

const { t } = useI18n();

const links = computed(() =>
  [
    {
      key: "homepage",
      icon: "fa-light fa-globe globe-rotate",
      href: props.fleet.homepage && `//${props.fleet.homepage}`,
      label: t("labels.homepage"),
    },
    {
      key: "guilded",
      icon: "fa-brands fa-guilded",
      href: props.fleet.guilded && `//${props.fleet.guilded}`,
      label: t("labels.guilded"),
    },
    {
      key: "discord",
      icon: "fa-brands fa-discord",
      href: props.fleet.discord && `//${props.fleet.discord}`,
      label: t("labels.discord"),
    },
    {
      key: "ts",
      icon: "fa-brands fa-teamspeak",
      href: props.fleet.ts,
      label: t("labels.fleet.ts"),
    },
    {
      key: "youtube",
      icon: "fa-brands fa-youtube",
      href: props.fleet.youtube && `//${props.fleet.youtube}`,
      label: t("labels.youtube"),
    },
    {
      key: "twitch",
      icon: "fa-brands fa-twitch",
      href: props.fleet.twitch && `//${props.fleet.twitch}`,
      label: t("labels.twitch"),
    },
  ].filter((link) => !!link.href),
);
</script>

<template>
  <div class="row">
    <div class="col-12">
      <div class="heading" :class="{ 'heading--compact': compact }">
        <Avatar
          v-if="fleet.logo"
          :avatar="fleet.logo.smallUrl"
          :transparent="!!fleet.logo"
          :round="false"
          :size="compact ? 'default' : 'large'"
          icon="fa-duotone fa-image"
        />
        <div
          class="heading-text"
          :class="{
            'heading-text--headquarters': fleet.headquarters && !compact,
          }"
        >
          <h1 class="large title">{{ fleet.name }} ({{ fleet.fid }})</h1>
          <div v-if="fleet.headquarters" class="heading-meta">
            <p class="fleet-headquarters" data-test="fleet-headquarters">
              <i class="fa-duotone fa-house-flag" aria-hidden="true" />
              <span class="sr-only">{{ t("labels.fleet.headquarters") }}</span>
              <LocationName
                :text="fleet.headquarters"
                :linked="fleet.headquartersLocation"
              />
            </p>
          </div>
        </div>
        <div v-if="compact" class="links links--inline">
          <RsiProfileLink
            v-if="fleet.rsiSid"
            :sid="fleet.rsiSid"
            :verified="fleet.rsiVerified"
            icon-only
          />
          <a
            v-for="link in links"
            :key="link.key"
            v-tooltip="link.label"
            :aria-label="link.label"
            :href="link.href ?? undefined"
            target="_blank"
            rel="noopener"
          >
            <i :class="link.icon" />
          </a>
        </div>
      </div>
      <FidNotice v-if="canManage" :fleet="fleet" dismissible>
        <template #actions>
          <router-link
            :to="{ name: 'fleet-settings-rsi', params: { slug: fleet.slug } }"
          >
            {{ t("actions.fleet.rsiVerification.verify") }}
            <i class="fa-light fa-chevron-right" />
          </router-link>
        </template>
      </FidNotice>
    </div>
  </div>
  <div v-if="!compact" class="row">
    <div class="col-12 links">
      <a
        v-if="links[0]?.key === 'homepage'"
        v-tooltip="links[0].label"
        :aria-label="links[0].label"
        :href="links[0].href ?? undefined"
        target="_blank"
        rel="noopener"
      >
        <i :class="links[0].icon" />
      </a>
      <RsiProfileLink
        v-if="fleet.rsiSid"
        :sid="fleet.rsiSid"
        :verified="fleet.rsiVerified"
        icon-only
        large
      />
      <a
        v-for="link in links.filter(({ key }) => key !== 'homepage')"
        :key="link.key"
        v-tooltip="link.label"
        :aria-label="link.label"
        :href="link.href ?? undefined"
        target="_blank"
        rel="noopener"
      >
        <i :class="link.icon" />
      </a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.fleet-headquarters {
  display: flex;
  align-items: center;
  gap: 8px;
  max-width: 100%;
  margin: 0;
  padding: 4px 14px;
  background-color: var(--color-control, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: 999px;
  font-size: 14px;
  color: var(--color-text-dim, #959595);

  > i {
    color: var(--color-muted, #7a8288);
  }
}

@import "./index.scss";
</style>
