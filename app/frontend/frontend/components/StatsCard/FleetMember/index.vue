<script lang="ts">
export default {
  name: "FleetMemberStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import ContactLinks from "@/frontend/components/StatsCard/ContactLinks/index.vue";
import MemberAvatar from "@/frontend/components/Fleets/MemberAvatar/index.vue";
import { useMemberPresence } from "@/frontend/composables/useMemberPresence";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type StatsCardBadge,
  type StatsCardStatus,
} from "@/frontend/components/StatsCard/types";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";
import { type FleetMember } from "@/services/fyApi";

type Props = {
  member?: FleetMember;
  name?: string;
  // The fleet's RSI SID, where it has one: without it there is nothing a
  // member could be verified against, and no status is said.
  fleetSid?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  member: undefined,
  name: undefined,
  fleetSid: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t, l, timeDistance } = useI18n();

const { onlineFor } = useMemberPresence();

const subtitle = computed(() => {
  const member = props.member;
  if (!member) return undefined;

  // The role leads here rather than in the eyebrow, which the status pill
  // beside it left too narrow to read.
  return [
    member.fleetRole?.name,
    member.nickname,
    member.rsiHandle
      ? t("labels.statsCard.rsiHandle", { handle: member.rsiHandle })
      : undefined,
  ]
    .filter(Boolean)
    .join(" · ");
});

const status = computed<StatsCardStatus | undefined>(() => {
  if (!props.member || !props.fleetSid) return undefined;

  return props.member.verified
    ? {
        label: t("labels.fleet.members.card.verified"),
        tone: "success",
      }
    : {
        label: t("labels.fleet.members.card.unverified"),
        tone: "warning",
      };
});

// The key facts as the card's badges; the location, which runs long, on a
// line of its own below them.
const badges = computed<StatsCardBadge[]>(() => {
  const member = props.member;
  if (!member) return [];

  return [
    member.acceptedAt && {
      key: "joined",
      label: t("labels.fleet.members.joined"),
      value: l(member.acceptedAt, "datetime.formats.date"),
    },
    {
      key: "lastActive",
      label: t("labels.user.lastActiveAt"),
      value: member.lastActiveAt
        ? timeDistance(member.lastActiveAt)
        : t("labels.fleet.members.health.facts.neverActive"),
    },
  ].filter(Boolean) as StatsCardBadge[];
});

const stats = computed<HardpointStat[]>(() =>
  props.member?.currentSystem
    ? [
        {
          label: t("labels.user.currentSystem"),
          value: props.member.currentSystem,
          wide: true,
        },
      ]
    : [],
);
</script>

<template>
  <StatsCard
    compact
    :title="member?.username || name || ''"
    kind="FleetMember"
    :subtitle="subtitle"
    :status="status"
    :badges="badges"
    large-icon
    :stats="stats"
    :to="to === false ? undefined : to"
    :loading="loading"
    :unavailable="!loading && !member"
    @navigate="emit('navigate')"
  >
    <!-- The roster's own bubble, in the head where the other cards draw their
         icon: the same squadron mark and presence dot, at a size to read. -->
    <template v-if="member" #icon>
      <MemberAvatar
        :member="member"
        :online="onlineFor(member)"
        show-squadrons
        size="medium"
      />
    </template>

    <ContactLinks
      :rsi-handle="member?.rsiHandle"
      :discord-url="member?.discordProfileUrl"
    />
  </StatsCard>
</template>
