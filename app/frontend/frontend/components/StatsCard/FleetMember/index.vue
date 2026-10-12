<script lang="ts">
export default {
  name: "FleetMemberStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import MemberContactMenu from "@/frontend/components/base/MemberContactMenu/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type StatsCardBadge,
  type StatsCardStatus,
} from "@/frontend/components/StatsCard/types";
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

const subtitle = computed(() => {
  const member = props.member;
  if (!member) return undefined;

  return [
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
        label: t("labels.fleet.members.card.verified", { sid: props.fleetSid }),
        tone: "success",
      }
    : {
        label: t("labels.fleet.members.card.unverified", {
          sid: props.fleetSid,
        }),
        tone: "warning",
      };
});

const badges = computed<StatsCardBadge[]>(() => {
  const member = props.member;
  if (!member) return [];

  const squadron = member.squadrons?.find((entry) => !entry.team);

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
    squadron && {
      key: "squadron",
      label: t("labels.fleet.members.card.squadron"),
      value: squadron.name,
    },
    member.currentSystem && {
      key: "location",
      label: t("labels.user.currentSystem"),
      value: member.currentSystem,
    },
  ].filter(Boolean) as StatsCardBadge[];
});

const contactable = computed(
  () => !!props.member?.rsiHandle || !!props.member?.discordProfileUrl,
);
</script>

<template>
  <StatsCard
    compact
    :title="member?.username || name || ''"
    kind="FleetMember"
    :category="member?.fleetRole?.name"
    :subtitle="subtitle"
    :status="status"
    :image="member?.avatar?.mediumUrl"
    :badges="badges"
    :to="to === false ? undefined : to"
    :loading="loading"
    :unavailable="!loading && !member"
    @navigate="emit('navigate')"
  >
    <template v-if="contactable && member" #rows>
      <MemberContactMenu :member="member" />
    </template>
  </StatsCard>
</template>
