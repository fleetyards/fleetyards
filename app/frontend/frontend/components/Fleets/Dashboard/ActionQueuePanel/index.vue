<script lang="ts">
export default {
  name: "FleetDashboardActionQueuePanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { useQueryClient } from "@tanstack/vue-query";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import DashboardEmpty from "@/frontend/components/Fleets/Dashboard/DashboardEmpty/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  FleetInventoryTransfersDirection,
  InventoryTransferStateEnum,
  getFleetActivityQueryKey,
  useAcceptFleetMember,
  useDeclineFleetMember,
  useFleetInventoryTransfers,
  useFleetMembers,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  canAnswerJoinRequests: boolean;
  canAnswerTransfers: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const comlink = useComlink();

const queryClient = useQueryClient();

const fleetSlug = computed(() => props.fleet.slug);

const SHOWN = 3;

const {
  data: requests,
  isLoading: requestsLoading,
  isFetching: requestsFetching,
  isError: requestsFailed,
  refetch: refetchRequests,
} = useFleetMembers(
  fleetSlug,
  { perPage: String(SHOWN), q: { stateIn: ["requested"] } },
  {
    query: {
      ...liveQuery,
      enabled: computed(() => props.canAnswerJoinRequests),
    },
  },
);

const {
  data: transfers,
  isLoading: transfersLoading,
  isFetching: transfersFetching,
  isError: transfersFailed,
} = useFleetInventoryTransfers(
  fleetSlug,
  {
    direction: FleetInventoryTransfersDirection.incoming,
    q: { stateEq: InventoryTransferStateEnum.PENDING },
  },
  {
    query: {
      ...liveQuery,
      enabled: computed(() => props.canAnswerTransfers),
    },
  },
);

const requestItems = computed(() =>
  props.canAnswerJoinRequests ? (requests.value?.items ?? []) : [],
);

const requestCount = computed(
  () =>
    requests.value?.meta.pagination?.totalCount ?? requestItems.value.length,
);

const transferCount = computed(() =>
  props.canAnswerTransfers
    ? (transfers.value?.meta.pagination?.totalCount ??
      transfers.value?.items.length ??
      0)
    : 0,
);

const loading = computed(
  () =>
    (props.canAnswerJoinRequests && requestsLoading.value) ||
    (props.canAnswerTransfers && transfersLoading.value),
);

// A disabled query never fetches, so these need no guard of their own.
const fetching = computed(
  () => requestsFetching.value || transfersFetching.value,
);

const failed = computed(() => requestsFailed.value || transfersFailed.value);

const empty = computed(
  () => !requestItems.value.length && !transferCount.value,
);

const acceptMutation = useAcceptFleetMember();

const declineMutation = useDeclineFleetMember();

const answering = ref<string | null>(null);

const answer = async (member: FleetMember, accept: boolean) => {
  answering.value = member.username;

  const mutation = accept ? acceptMutation : declineMutation;
  const messages = accept
    ? "messages.fleet.members.accept"
    : "messages.fleet.members.decline";

  try {
    await mutation.mutateAsync({
      fleetSlug: fleetSlug.value,
      username: member.username,
    });

    comlink.emit("fleet-member-update");
    void refetchRequests();
    void queryClient.invalidateQueries({
      queryKey: getFleetActivityQueryKey(fleetSlug.value),
    });

    displaySuccess({ text: t(`${messages}.success`) });
  } catch {
    displayAlert({ text: t(`${messages}.failure`) });
  } finally {
    answering.value = null;
  }
};
</script>

<template>
  <DashboardPanel
    :title="t('fleetDashboard.actionQueue.title')"
    :pending="loading"
    :fetching="fetching"
    :failed="failed"
    :empty="empty"
    data-test="fleet-dashboard-action-queue"
  >
    <section v-if="requestItems.length" class="action-queue__group">
      <router-link
        :to="{
          name: 'fleet-members-index',
          params: { slug: fleet.slug },
          query: { view: 'invites' },
        }"
        class="action-queue__headline"
        data-test="fleet-dashboard-join-requests"
      >
        <i class="fa-light fa-user-plus" aria-hidden="true" />
        {{
          t("fleetDashboard.actionQueue.joinRequests", { count: requestCount })
        }}
      </router-link>
      <ul class="action-queue__list">
        <li
          v-for="member in requestItems"
          :key="member.id"
          class="action-queue__request"
          :data-test="`fleet-dashboard-join-request-${member.username}`"
        >
          <Avatar :avatar="member.avatar?.smallUrl" size="small" />
          <span class="action-queue__name">{{ member.username }}</span>
          <BtnGroup>
            <Btn
              :size="BtnSizesEnum.SM"
              :aria-label="t('actions.fleet.members.accept')"
              :loading="answering === member.username"
              :disabled="!!answering"
              data-test="fleet-dashboard-join-request-accept"
              @click="answer(member, true)"
            >
              <i class="fa-light fa-check" />
            </Btn>
            <Btn
              :size="BtnSizesEnum.SM"
              :aria-label="t('actions.fleet.members.decline')"
              :disabled="!!answering"
              data-test="fleet-dashboard-join-request-decline"
              @click="answer(member, false)"
            >
              <i class="fa-light fa-xmark" />
            </Btn>
          </BtnGroup>
        </li>
      </ul>
    </section>
    <section v-if="transferCount" class="action-queue__group">
      <router-link
        :to="{
          name: 'fleet-logistics-transfers',
          params: { slug: fleet.slug },
        }"
        class="action-queue__headline"
        data-test="fleet-dashboard-pending-transfers"
      >
        <i class="fa-light fa-truck-ramp-box" aria-hidden="true" />
        {{
          t("fleetDashboard.actionQueue.pendingTransfers", {
            count: transferCount,
          })
        }}
        <i class="fa-light fa-chevron-right" aria-hidden="true" />
      </router-link>
    </section>
    <template #empty>
      <DashboardEmpty
        icon="fa-check"
        :title="t('fleetDashboard.actionQueue.empty.title')"
        :hint="t('fleetDashboard.actionQueue.empty.hint')"
      />
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.action-queue__group + .action-queue__group {
  margin-top: 16px;
}

.action-queue__headline {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.action-queue__list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 10px 0 0;
  padding: 0;
  list-style: none;
}

.action-queue__request {
  display: flex;
  align-items: center;
  gap: 10px;
}

.action-queue__name {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
