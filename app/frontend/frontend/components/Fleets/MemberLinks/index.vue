<script lang="ts">
export default {
  name: "FleetMemberLinks",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { FleetMember } from "@/services/fyApi";

type Props = {
  member: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <div class="member-links">
    <a
      v-tooltip="t('labels.hangar')"
      :aria-label="t('labels.hangar')"
      :href="`/hangar/${props.member.username}`"
      target="_blank"
      rel="noopener"
    >
      <i class="fa-duotone fa-bookmark" />
    </a>
    <a
      v-if="props.member.homepage"
      v-tooltip="t('labels.homepage')"
      :aria-label="t('labels.homepage')"
      :href="`//${props.member.homepage}`"
      target="_blank"
      rel="noopener"
    >
      <i class="fa-light fa-globe globe-rotate" />
    </a>
    <a
      v-if="props.member.rsiHandle"
      v-tooltip="t('nav.rsiProfile')"
      :aria-label="t('nav.rsiProfile')"
      :href="`https://robertsspaceindustries.com/citizens/${props.member.rsiHandle}`"
      target="_blank"
      rel="noopener"
    >
      <i class="icon icon-rsi icon-small" />
    </a>
    <a
      v-if="props.member.youtube"
      v-tooltip="t('labels.youtube')"
      :aria-label="t('labels.youtube')"
      :href="`//${props.member.youtube}`"
      target="_blank"
      rel="noopener"
    >
      <i class="fa-brands fa-youtube" />
    </a>
    <a
      v-if="props.member.twitch"
      v-tooltip="t('labels.twitch')"
      :aria-label="t('labels.twitch')"
      :href="`//${props.member.twitch}`"
      target="_blank"
      rel="noopener"
    >
      <i class="fa-brands fa-twitch" />
    </a>
    <a
      v-if="props.member.guilded"
      v-tooltip="t('labels.guilded')"
      :aria-label="t('labels.guilded')"
      :href="`//${props.member.guilded}`"
      target="_blank"
      rel="noopener"
    >
      <i class="fa-brands fa-guilded" />
    </a>
    <a
      v-if="props.member.discord"
      v-tooltip="t('labels.discord')"
      :aria-label="t('labels.discord')"
      :href="`//${props.member.discord}`"
      target="_blank"
      rel="noopener"
    >
      <i class="fa-brands fa-discord" />
    </a>
  </div>
</template>

<style lang="scss" scoped>
.member-links {
  display: flex;
  gap: 10px;
  align-items: center;
  font-size: 1.2em;

  a {
    opacity: 0.7;

    &:hover {
      opacity: 1;
    }
  }
}
</style>
