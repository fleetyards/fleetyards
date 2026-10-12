<script lang="ts">
export default {
  name: "FleetMemberStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import ContactLinks from "@/frontend/components/StatsCard/ContactLinks/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
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
        label: t("labels.fleet.members.card.verified"),
        tone: "success",
      }
    : {
        label: t("labels.fleet.members.card.unverified"),
        tone: "warning",
      };
});

// Squadrons before teams, as the roster badges them.
const squadrons = computed(() =>
  [...(props.member?.squadrons ?? [])].sort(
    (a, b) => Number(a.team) - Number(b.team),
  ),
);

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
    // Drawn as the squadrons' emblems; the names are the badge's text for its
    // tooltip and for assistive tech.
    squadrons.value.length && {
      key: "squadrons",
      label: t("labels.fleet.members.card.squadrons"),
      value: squadrons.value.map((squadron) => squadron.name).join(", "),
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
    :category="member?.fleetRole?.name"
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
    <!-- In the head, where the other cards draw their icon: as the card's
         image an avatar was cropped to a strip of forehead. -->
    <template v-if="member?.avatar?.mediumUrl" #icon>
      <img :src="member.avatar.mediumUrl" alt="" class="member-card__avatar" />
    </template>

    <template #badge-squadrons>
      <span class="member-card__squadrons">
        <span
          v-for="squadron in squadrons"
          :key="squadron.id"
          v-tooltip="squadron.name"
        >
          <SquadronEmblem :squadron="squadron" :size="22" />
        </span>
      </span>
    </template>

    <ContactLinks
      :rsi-handle="member?.rsiHandle"
      :discord-url="member?.discordProfileUrl"
    />
  </StatsCard>
</template>

<style lang="scss" scoped>
.member-card__avatar {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
}

.member-card__squadrons {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 4px;
  vertical-align: middle;
}
</style>
