<script lang="ts">
export default {
  name: "FleetMembersHealthPage",
};
</script>

<script lang="ts" setup>
import { keepPreviousData } from "@tanstack/vue-query";
import { subDays, formatISO } from "date-fns";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import AsyncData from "@/shared/components/AsyncData.vue";
import CheckPanel from "@/frontend/components/Fleets/MemberHealth/CheckPanel/index.vue";
import HealthRow from "@/frontend/components/Fleets/MemberHealth/Row/index.vue";
import MemberMenu from "@/frontend/components/Fleets/MemberHealth/MemberMenu/index.vue";
import {
  MEMBER_HEALTH_GROUPS,
  byUrgency,
  memberHealthChecks,
  needsAttention,
  type MemberHealthCheck,
  type MemberHealthCheckKey,
} from "@/frontend/utils/memberHealth";
import {
  useAcceptFleetMember,
  useDeclineFleetMember,
  useDestroyFleetInviteUrl,
  useFleetMemberHealth,
  type Fleet,
  type FleetMember,
  type FleetMemberHealthMember,
  type FleetMemberHealthParams,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t, l, timeDistance } = useI18n();

const route = useRoute();

const comlink = useComlink();

const { displaySuccess, displayAlert } = useAppNotifications();

const DAY_STEPS = [14, 30, 60, 90, 180];

const DEFAULT_DAYS = 30;

const days = computed(() => {
  const value = Number(route.query.days);

  return DAY_STEPS.includes(value) ? value : DEFAULT_DAYS;
});

const params = computed<FleetMemberHealthParams>(() => ({
  inactiveDays: days.value,
}));

const { data: health, ...asyncStatus } = useFleetMemberHealth(
  props.fleet.slug,
  params,
  // A new threshold keeps the old answer on screen until the new one arrives,
  // instead of dropping the whole page to a spinner.
  { query: { placeholderData: keepPreviousData } },
);

const refetch = () => {
  void asyncStatus.refetch();
};

let offMemberUpdate: (() => void) | undefined;

onMounted(() => {
  offMemberUpdate = comlink.on("fleet-member-update", refetch);
});

onUnmounted(() => {
  offMemberUpdate?.();
});

const capabilities = computed(() => props.membership?.capabilities);

const sid = computed(() => props.fleet.rsiSid ?? "");

const checks = computed(() =>
  health.value ? memberHealthChecks(health.value) : [],
);

const overview = computed(() => byUrgency(checks.value));

const attentionCount = computed(
  () => checks.value.filter(needsAttention).length,
);

const groups = computed(() =>
  MEMBER_HEALTH_GROUPS.map((group) => ({
    group,
    checks: checks.value.filter((check) => check.group === group),
  })).filter((entry) => entry.checks.length),
);

const checkText = (check: MemberHealthCheck, part: string) =>
  t(`labels.fleet.members.health.checks.${check.key}.${part}`, {
    sid: sid.value,
    count: days.value,
  });

const membersLink = (query: Record<string, string>) => ({
  name: "fleet-members-index",
  params: { slug: props.fleet.slug },
  query,
});

// The full lists live on the members page, filtered the same way.
const moreLinks = computed<Partial<Record<MemberHealthCheckKey, object>>>(
  () => ({
    unverified: membersLink({ verifiedEq: "false" }),
    noHandle: membersLink({ withoutRsiHandle: "true" }),
    inactive: membersLink({
      inactiveSince: formatISO(subDays(new Date(), days.value), {
        representation: "date",
      }),
      s: "lastActiveAt asc",
    }),
    joinRequests: membersLink({ view: "invites" }),
    invitations: membersLink({ view: "invites" }),
    discord: membersLink({ withoutDiscord: "true" }),
    noSquadron: membersLink({ withoutSquadron: "true" }),
  }),
);

const sections = computed(() => {
  const value = health.value;
  if (!value) return {};

  return {
    admins: value.admins,
    unverified: value.unverifiedMembers,
    noHandle: value.membersWithoutRsiHandle,
    inactive: value.inactiveMembers,
    joinRequests: value.waitingJoinRequests,
    invitations: value.unansweredInvitations,
    discord: value.membersWithoutDiscord,
    noSquadron: value.membersWithoutSquadron,
  } as Partial<
    Record<
      MemberHealthCheckKey,
      { totalCount: number; items: FleetMemberHealthMember[] } | null
    >
  >;
});

const membersOf = (check: MemberHealthCheck) =>
  sections.value[check.key]?.items ?? [];

const moreFor = (check: MemberHealthCheck) => {
  const section = sections.value[check.key];
  const link = moreLinks.value[check.key];
  if (!section || !link || section.totalCount <= section.items.length) {
    return undefined;
  }

  return link;
};

const daysLink = (value: number) => ({
  query: { ...route.query, days: value === DEFAULT_DAYS ? undefined : value },
});

// Requests and invitations are not on the roster: the member list only finds
// them in its invites view.
const PENDING_CHECKS: MemberHealthCheckKey[] = ["joinRequests", "invitations"];

const memberTo = (check: MemberHealthCheck, member: FleetMemberHealthMember) =>
  membersLink(
    PENDING_CHECKS.includes(check.key)
      ? { view: "invites", searchCont: member.username }
      : { searchCont: member.username },
  );

const joinedLine = (member: FleetMemberHealthMember) =>
  member.acceptedAt
    ? t("labels.fleet.members.health.facts.joined", {
        date: l(member.acceptedAt, "datetime.formats.date"),
      })
    : undefined;

const lastActive = (member: FleetMemberHealthMember) =>
  member.lastActiveAt
    ? t("labels.fleet.members.health.facts.lastActive", {
        distance: timeDistance(member.lastActiveAt),
      })
    : t("labels.fleet.members.health.facts.neverActive");

const gapFact = (member: FleetMemberHealthMember) =>
  member.verificationGap
    ? t(`labels.fleet.members.health.gaps.${member.verificationGap}`, {
        sid: sid.value,
      })
    : undefined;

const gapSub = (member: FleetMemberHealthMember) => {
  if (
    member.verificationGap === "org_not_listed" &&
    member.rsiOrganizationsCheckedAt
  ) {
    return t("labels.fleet.members.health.facts.checked", {
      distance: timeDistance(member.rsiOrganizationsCheckedAt),
    });
  }

  return member.rsiHandle ?? undefined;
};

const FACTS: Partial<Record<MemberHealthCheckKey, string>> = {
  discord: "noDiscord",
  noSquadron: "noSquadron",
  noHandle: "noHandle",
};

const memberFact = (
  check: MemberHealthCheck,
  member: FleetMemberHealthMember,
) => {
  if (check.key === "unverified") return gapFact(member);
  if (check.key === "joinRequests" && member.requestedAt) {
    return t("labels.fleet.members.health.facts.requested", {
      distance: timeDistance(member.requestedAt),
    });
  }
  if (check.key === "invitations" && member.invitedAt) {
    return t("labels.fleet.members.health.facts.invited", {
      distance: timeDistance(member.invitedAt),
    });
  }
  const fact = FACTS[check.key];
  if (fact) return t(`labels.fleet.members.health.facts.${fact}`);

  return lastActive(member);
};

const memberSubline = (
  check: MemberHealthCheck,
  member: FleetMemberHealthMember,
) => {
  if (check.key === "invitations" && member.invitedBy) {
    return t("labels.fleet.members.health.facts.invitedBy", {
      name: member.invitedBy,
    });
  }

  return joinedLine(member);
};

const singleAdmin = computed(() => health.value?.admins.items[0]);

const orgGap = computed(() => {
  const count = health.value?.rsiMemberCount;
  if (count == null || !health.value) return null;

  return Math.max(count - health.value.memberCount, 0);
});

const answering = ref<string | null>(null);

const acceptMutation = useAcceptFleetMember();

const declineMutation = useDeclineFleetMember();

const answer = async (member: FleetMemberHealthMember, accept: boolean) => {
  answering.value = member.username;
  const messages = accept
    ? "messages.fleet.members.accept"
    : "messages.fleet.members.decline";

  try {
    await (accept ? acceptMutation : declineMutation).mutateAsync({
      fleetSlug: props.fleet.slug,
      username: member.username,
    });
    comlink.emit("fleet-member-update");
    displaySuccess({ text: t(`${messages}.success`) });
  } catch {
    displayAlert({ text: t(`${messages}.failure`) });
  } finally {
    answering.value = null;
  }
};

const destroyInviteUrlMutation = useDestroyFleetInviteUrl();

// No confirmation, like the invite link list: a link is cheap to make again.
const deleteInviteUrl = async (token: string) => {
  try {
    await destroyInviteUrlMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      token,
    });
    refetch();
  } catch {
    displayAlert({ text: t("labels.fleet.members.health.deleteLinkFailed") });
  }
};

const inviteUrlFact = (inviteUrl: {
  expiresAfter?: string | null;
  limit?: number | null;
}) => {
  if (inviteUrl.expiresAfter && new Date(inviteUrl.expiresAfter) < new Date()) {
    return t("labels.fleet.members.health.facts.linkExpired", {
      distance: timeDistance(inviteUrl.expiresAfter),
    });
  }
  if (inviteUrl.limit != null && inviteUrl.limit <= 0) {
    return t("labels.fleet.members.health.facts.linkUsedUp");
  }

  return t("labels.fleet.members.health.facts.linkUnlimited");
};

const openInviteUrlModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/InviteUrlModal/index.vue"),
    props: { fleet: props.fleet },
  });
};

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-members-index", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.members.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading>
    {{ t("headlines.fleets.members.health") }}
  </Heading>

  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="health" class="member-health">
        <p class="member-health__summary" data-test="health-summary">
          {{
            attentionCount
              ? t("labels.fleet.members.health.summary.attention", {
                  count: attentionCount,
                  total: checks.length,
                })
              : t("labels.fleet.members.health.summary.clear", {
                  total: checks.length,
                })
          }}
        </p>

        <nav
          class="member-health__overview"
          :aria-label="t('labels.fleet.members.health.overview')"
        >
          <a
            v-for="check in overview"
            :key="check.key"
            :href="`#health-${check.key}`"
            class="member-health__overview-item"
            :data-tone="check.tone"
            :data-test="`health-overview-${check.key}`"
          >
            <i
              class="fa-light member-health__overview-icon"
              :class="{
                'fa-check': check.tone === 'ok',
                'fa-circle-exclamation': check.tone === 'attention',
                'fa-triangle-exclamation': check.tone === 'critical',
                'fa-circle-info': check.tone === 'info',
              }"
              aria-hidden="true"
            />
            <span class="member-health__overview-label">
              {{ checkText(check, "overview") }}
            </span>
            <span class="member-health__overview-count">{{
              check.display
            }}</span>
          </a>
        </nav>

        <div
          v-for="entry in groups"
          :key="entry.group"
          class="member-health__group"
        >
          <h2 class="member-health__group-title">
            {{ t(`labels.fleet.members.health.groups.${entry.group}`) }}
          </h2>

          <CheckPanel
            v-for="check in entry.checks"
            :key="check.key"
            :check="check"
            :title="checkText(check, 'title')"
            :description="checkText(check, 'description')"
            :clear-line="checkText(check, 'clear')"
            :more="moreFor(check)"
            :more-label="
              t('actions.fleet.members.health.showAll', {
                count: sections[check.key]?.totalCount ?? 0,
              })
            "
          >
            <template v-if="check.key === 'emptyRoles'" #actions>
              <Btn
                :size="BtnSizesEnum.SM"
                :to="{
                  name: 'fleet-settings-roles',
                  params: { slug: fleet.slug },
                }"
                data-test="health-roles-settings"
              >
                {{ t("actions.fleet.members.health.roleSettings") }}
              </Btn>
            </template>
            <template v-else-if="check.key === 'inactive'" #actions>
              <BtnGroup segmented>
                <Btn
                  v-for="step in DAY_STEPS"
                  :key="step"
                  :size="BtnSizesEnum.SM"
                  :to="daysLink(step)"
                  :active="days === step"
                  :data-test="`health-days-${step}`"
                >
                  {{ t("labels.fleet.members.health.days", { count: step }) }}
                </Btn>
              </BtnGroup>
            </template>
            <template v-else-if="check.key === 'inviteUrls'" #actions>
              <Btn :size="BtnSizesEnum.SM" @click="openInviteUrlModal">
                {{ t("actions.fleet.members.health.inviteLinks") }}
              </Btn>
            </template>
            <template v-else-if="check.key === 'discord'" #actions>
              <Btn
                :size="BtnSizesEnum.SM"
                :to="{
                  name: 'fleet-settings-discord',
                  params: { slug: fleet.slug },
                }"
              >
                {{ t("actions.fleet.members.health.discordSettings") }}
              </Btn>
            </template>

            <template #before>
              <Alert
                v-if="check.key === 'admins' && singleAdmin"
                variant="danger"
                size="compact"
                class="member-health__note"
                data-test="health-single-admin"
              >
                {{
                  t("labels.fleet.members.health.singleAdmin", {
                    name: singleAdmin.username,
                    fleet: fleet.name,
                  })
                }}
              </Alert>
              <template v-if="check.key === 'unverified'">
                <dl
                  v-if="health.rsiMemberCount != null"
                  class="member-health__stats"
                  data-test="health-org-stats"
                >
                  <div>
                    <dt>
                      {{
                        t("labels.fleet.members.health.orgStats.rsi", { sid })
                      }}
                    </dt>
                    <dd>{{ health.rsiMemberCount }}</dd>
                  </div>
                  <div>
                    <dt>
                      {{ t("labels.fleet.members.health.orgStats.roster") }}
                    </dt>
                    <dd>{{ health.memberCount }}</dd>
                  </div>
                  <div>
                    <dt>{{ t("labels.fleet.members.health.orgStats.gap") }}</dt>
                    <dd class="member-health__stat--loud">{{ orgGap }}</dd>
                  </div>
                </dl>
                <Alert
                  v-if="!health.fleetRsiVerified"
                  variant="warning"
                  size="compact"
                  class="member-health__note"
                  data-test="health-fleet-unverified"
                >
                  {{
                    t("labels.fleet.members.health.fleetNotVerified", { sid })
                  }}
                  <router-link
                    :to="{
                      name: 'fleet-settings-rsi',
                      params: { slug: fleet.slug },
                    }"
                  >
                    {{ t("actions.fleet.members.health.verifyOrg") }}
                  </router-link>
                </Alert>
              </template>
            </template>

            <ul v-if="check.key === 'emptyRoles'" class="member-health__chips">
              <li
                v-for="role in health.emptyRoles ?? []"
                :key="role.id"
                :data-test="`health-empty-role-${role.slug}`"
              >
                {{ role.name }}
              </li>
            </ul>

            <p
              v-else-if="check.key === 'hiddenShips'"
              class="member-health__quiet"
            >
              {{
                t("labels.fleet.members.health.hiddenShips", {
                  count: health.hiddenShipsCount,
                })
              }}
            </p>

            <ul
              v-else-if="check.key === 'inviteUrls'"
              class="member-health__rows"
            >
              <HealthRow
                v-for="inviteUrl in health.staleInviteUrls?.items ?? []"
                :key="inviteUrl.token"
                :title="inviteUrl.token"
                mark="URL"
                :subline="
                  inviteUrl.createdBy
                    ? t('labels.fleet.members.health.facts.createdBy', {
                        name: inviteUrl.createdBy,
                      })
                    : undefined
                "
                :fact="inviteUrlFact(inviteUrl)"
                :fact-sub="
                  t('labels.fleet.members.health.facts.used', {
                    count: inviteUrl.usageCount,
                  })
                "
                :fact-loud="!inviteUrl.expiresAfter && inviteUrl.limit == null"
                :data-test="`health-invite-url-${inviteUrl.token}`"
              >
                <template v-if="capabilities?.destroyInvites" #actions>
                  <Btn
                    :size="BtnSizesEnum.SM"
                    @click="deleteInviteUrl(inviteUrl.token)"
                  >
                    {{ t("actions.fleet.members.health.deleteLink") }}
                  </Btn>
                </template>
              </HealthRow>
            </ul>

            <ul
              v-else-if="check.key === 'emptySquadrons'"
              class="member-health__rows"
            >
              <HealthRow
                v-for="squadron in health.emptySquadrons?.items ?? []"
                :key="squadron.id"
                :title="squadron.name"
                :to="{
                  name: 'fleet-squadron',
                  params: { slug: fleet.slug, squadron: squadron.slug },
                }"
                :mark="squadron.name.slice(0, 2).toUpperCase()"
                :subline="
                  squadron.team
                    ? t('labels.fleet.members.health.facts.team')
                    : undefined
                "
                :fact="
                  t('labels.fleet.members.health.facts.created', {
                    date: l(squadron.createdAt, 'datetime.formats.date'),
                  })
                "
              />
            </ul>

            <ul v-else class="member-health__rows">
              <HealthRow
                v-for="member in membersOf(check)"
                :key="member.id"
                :title="member.username"
                :to="memberTo(check, member)"
                :avatar="member.avatar?.smallUrl"
                :subline="memberSubline(check, member)"
                :chip="member.fleetRole?.name"
                :chip-loud="check.key === 'inactive' && member.leader"
                :fact="memberFact(check, member)"
                :fact-sub="
                  check.key === 'unverified' ? gapSub(member) : undefined
                "
                :fact-loud="check.key === 'inactive' && !member.lastActiveAt"
                :data-test="`health-${check.key}-${member.username}`"
              >
                <template v-if="check.key === 'joinRequests'" #actions>
                  <Btn
                    :size="BtnSizesEnum.SM"
                    :loading="answering === member.username"
                    :disabled="!!answering"
                    data-test="health-accept"
                    @click="answer(member, true)"
                  >
                    {{ t("actions.fleet.members.accept") }}
                  </Btn>
                  <Btn
                    :size="BtnSizesEnum.SM"
                    :disabled="!!answering"
                    data-test="health-decline"
                    @click="answer(member, false)"
                  >
                    {{ t("actions.fleet.members.decline") }}
                  </Btn>
                </template>
                <template v-else-if="check.key !== 'admins'" #actions>
                  <MemberMenu
                    :fleet-slug="fleet.slug"
                    :member="member"
                    :capabilities="capabilities"
                    :demote="check.key === 'inactive' && member.leader"
                    :revoke="check.key === 'invitations'"
                  />
                </template>
              </HealthRow>
            </ul>
          </CheckPanel>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.member-health {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.member-health__summary {
  margin: 0;
  color: var(--color-text-dim, #959595);
}

.member-health__overview {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 8px;
}

.member-health__overview-item {
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 44px;
  padding: 8px 12px;
  border: 1px solid rgb(122 130 136 / 0.35);
  border-radius: 3px;
  color: var(--color-text, #c8c8c8);

  &[data-tone="critical"] {
    border-color: var(--color-danger, #dc3545);
  }
}

.member-health__overview-icon {
  [data-tone="ok"] > & {
    color: var(--color-success, #5cb85c);
  }

  [data-tone="attention"] > & {
    color: var(--color-warning, #fa6800);
  }

  [data-tone="critical"] > & {
    color: var(--color-danger, #dc3545);
  }

  [data-tone="info"] > & {
    color: var(--color-muted, #7a8288);
  }
}

.member-health__overview-label {
  flex: 1 1 auto;
  min-width: 0;
}

.member-health__overview-count {
  font-family: Orbitron, sans-serif;
  font-weight: 700;
}

.member-health__group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.member-health__group-title {
  margin: 16px 0 0;
  color: var(--color-text-dim, #959595);
  font-family: Orbitron, sans-serif;
  font-size: 15px;
  font-weight: 500;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.member-health__rows {
  margin: 0;
  padding: 0;
  list-style: none;
}

.member-health__chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0;
  padding: 14px 20px 16px;
  list-style: none;

  li {
    padding: 6px 12px;
    border: 1px dashed rgb(122 130 136 / 0.5);
    border-radius: 3px;
    color: var(--color-lifted, #eee);
  }
}

.member-health__quiet {
  margin: 0;
  padding: 14px 20px 16px;
}

.member-health__note {
  margin: 14px 20px 0;
}

.member-health__stats {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 28px;
  margin: 0;
  padding: 14px 20px;
  border-bottom: 1px solid rgb(122 130 136 / 0.15);

  dt {
    color: var(--color-text-dim, #959595);
    font-size: 12px;
    font-weight: 400;
  }

  dd {
    margin: 0;
    color: var(--color-lifted, #eee);
    font-family: Orbitron, sans-serif;
    font-size: 20px;
    font-weight: 700;
  }
}

.member-health__stat--loud {
  color: var(--color-warning, #fa6800);
}
</style>
