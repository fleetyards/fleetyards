<script lang="ts">
export default {
  name: "FleetDashboardOnlineMembersPanel",
};
</script>

<script lang="ts" setup>
import { useDebounceFn } from "@vueuse/core";
import { focusManager } from "@tanstack/vue-query";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import DashboardEmpty from "@/frontend/components/Fleets/Dashboard/DashboardEmpty/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { useI18n } from "@/shared/composables/useI18n";
import { usePresence } from "@/shared/composables/usePresence";
import { useFleetOnlineMembers, type Fleet } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

/*
 * Asked for once, then kept live by the presence pushes every co-member
 * already receives. Somebody going offline drops out at once. Somebody coming
 * online who is not listed yet means one more ask: the push carries an id, not
 * a member, and only the server knows whether they belong to this fleet.
 *
 * Each id is asked about once while it stays online, so a friend outside the
 * fleet does not ask on every push; going offline clears that, so the next
 * login asks again. The wait is spread over a few seconds per dashboard,
 * because every open dashboard of the fleet hears the same login at once.
 */
const ASK_AGAIN_AFTER_MS = 2_000 + Math.round(Math.random() * 8_000);

// The refocus ask is made here rather than by the query, so the panel knows
// which fetch the reader asked for.
const { data, refetch, isLoading, isFetching, isError } = useFleetOnlineMembers(
  computed(() => props.fleet.slug),
  { query: { ...liveQuery, refetchOnWindowFocus: false } },
);

/*
 * The asks presence pushes and reconnects set off keep the list in step behind
 * the reader's back; with the bar on each of them it would flicker on every
 * login in the fleet. Only the first answer and a refocus show it. The refocus
 * holds the bar until no fetch is out at all, so a push that restarts the
 * fetch under it does not take the bar away.
 */
const refocusing = ref(false);

watch(isFetching, (now) => {
  if (!now) refocusing.value = false;
});

onScopeDispose(
  focusManager.subscribe((focused) => {
    if (!focused || !data.value) return;

    refocusing.value = true;
    void refetch();
  }),
);

const { isOnline, knownOnlineIds, resets } = usePresence();

const listed = computed(() => data.value?.items ?? []);

const members = computed(() =>
  listed.value.filter((member) => isOnline(member.userId, true)),
);

const total = computed(() =>
  data.value
    ? data.value.totalCount - (listed.value.length - members.value.length)
    : undefined,
);

// No count until there is one: a zero before the answer reads as nobody.
const title = computed(() =>
  total.value === undefined
    ? t("fleetDashboard.online.titlePending")
    : t("fleetDashboard.online.title", { count: total.value }),
);

const more = computed(() => (total.value ?? 0) - members.value.length);

// Everybody the page listed has gone, and those online past it are still
// being asked for: neither a list nor nobody yet.
const waitingForMore = computed(
  () => !members.value.length && (total.value ?? 0) > 0,
);

const askedAbout = new Set<string>();

const askAgain = useDebounceFn(() => void refetch(), ASK_AGAIN_AFTER_MS);

watch(knownOnlineIds, (ids) => {
  // Before the first answer there is nothing to compare against, and the ask
  // already in flight will bring whoever is online.
  if (!data.value) return;

  [...askedAbout]
    .filter((id) => !ids.has(id))
    .forEach((id) => askedAbout.delete(id));

  const listedIds = new Set(listed.value.map(({ userId }) => userId));
  const unseen = [...ids].filter(
    (id) => !listedIds.has(id) && !askedAbout.has(id),
  );
  if (!unseen.length) return;

  unseen.forEach((id) => askedAbout.add(id));
  void askAgain();
});

// The page holds the first rows only; once all of them have gone, whoever is
// still online past them has to be asked for.
watch(
  () => members.value.length,
  (count) => {
    if (count === 0 && (total.value ?? 0) > 0) void askAgain();
  },
);

// Nothing sent while the socket was down is replayed, so after a reconnect the
// list is only as good as a fresh answer.
watch(resets, () => {
  askedAbout.clear();
  void refetch();
});
</script>

<template>
  <DashboardPanel
    :title="title"
    :pending="isLoading || waitingForMore"
    :fetching="refocusing"
    :failed="isError && !data"
    :empty="!members.length"
    :more="{ name: 'fleet-members-index', params: { slug: fleet.slug } }"
    data-test="fleet-dashboard-online"
  >
    <ul class="online-members">
      <li
        v-for="member in members"
        :key="member.userId"
        class="online-members__member"
        :data-test="`fleet-dashboard-online-${member.username}`"
      >
        <Avatar :avatar="member.avatar?.smallUrl" size="small" :online="true" />
        <span class="online-members__name">
          {{ member.nickname || member.username }}
        </span>
        <i
          v-if="member.friend"
          v-tooltip="t('fleetDashboard.online.friend')"
          class="fa-light fa-user-group online-members__friend"
          :aria-label="t('fleetDashboard.online.friend')"
          data-test="fleet-dashboard-online-friend"
        />
      </li>
    </ul>
    <p v-if="more > 0" class="online-members__more">
      {{ t("fleetDashboard.online.more", { count: more }) }}
    </p>
    <template #empty>
      <DashboardEmpty
        icon="fa-signal-stream"
        :title="t('fleetDashboard.online.empty.title')"
        :hint="t('fleetDashboard.online.empty.hint')"
      />
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.online-members {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.online-members__member {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.online-members__name {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.online-members__friend {
  color: var(--color-muted, #7a8288);
}

.online-members__more {
  margin: 10px 0 0;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}
</style>
