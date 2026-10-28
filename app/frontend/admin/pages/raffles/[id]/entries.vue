<script lang="ts">
export default {
  name: "AdminRaffleEntriesPage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import RaffleOverview from "@/admin/components/Raffles/Overview/index.vue";
import AnnouncementManualPosts from "@/admin/components/Announcements/ManualPosts/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import {
  type Raffle,
  type RaffleEntry,
  RaffleStatusEnum,
  useRaffleEntries,
  useDrawRaffle,
  useDestroyRaffle,
  getRaffleQueryKey,
  getRafflesQueryKey,
  getRaffleEntriesQueryKey,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const { displayConfirm, displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const { perPage, page, updatePerPage } = usePagination();

const entriesQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
}));

const { data: entries, ...asyncStatus } = useRaffleEntries(
  props.raffle.id,
  entriesQueryParams,
);

const invalidate = () =>
  Promise.all([
    queryClient.invalidateQueries({
      queryKey: getRaffleQueryKey(props.raffle.id),
    }),
    queryClient.invalidateQueries({ queryKey: getRafflesQueryKey() }),
    queryClient.invalidateQueries({
      queryKey: getRaffleEntriesQueryKey(props.raffle.id),
    }),
  ]);

const drawMutation = useDrawRaffle({ mutation: { onSettled: invalidate } });
const destroyMutation = useDestroyRaffle();

const router = useRouter();

const isDraft = computed(() => props.raffle.status === RaffleStatusEnum.DRAFT);

const destroy = () => {
  displayConfirm({
    tone: AppConfirmTonesEnum.DANGER,
    text: t("messages.confirm.raffle.destroy"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({ id: props.raffle.id })
        .then(async () => {
          await queryClient.invalidateQueries({
            queryKey: getRafflesQueryKey(),
          });
          displaySuccess({ text: t("messages.raffle.destroyed") });
          await router.push({ name: "admin-raffles" });
        })
        .catch((error) => {
          displayAlert({ text: error.response?.data?.message });
        });
    },
  });
};
const winner = computed(() => props.raffle.currentWinner);

const draw = () => {
  displayConfirm({
    tone: AppConfirmTonesEnum.DANGER,
    text: t("messages.confirm.raffle.draw"),
    onConfirm: async () => {
      await drawMutation
        .mutateAsync({ id: props.raffle.id })
        .then(() => {
          displaySuccess({ text: t("messages.raffle.drawn") });
        })
        .catch((error) => {
          displayAlert({
            text:
              error.response?.data?.message || t("messages.raffle.drawFailed"),
          });
        });
    },
  });
};

const columns: BaseTableCol<RaffleEntry>[] = [
  { name: "drawPosition", label: t("labels.raffleEntry.drawPosition") },
  { name: "username", label: t("labels.raffleEntry.username") },
  {
    name: "conditionsAcceptedAt",
    label: t("labels.raffleEntry.conditionsAcceptedAt"),
    mobile: false,
  },
  { name: "state", label: t("labels.raffleEntry.state") },
  { name: "mail", label: t("labels.raffleEntry.mail"), mobile: false },
];

const mailState = (status?: string) =>
  status ? t(`labels.raffleEntry.mailStatuses.${status}`) : "—";

const socialPosts = computed(() => [
  props.raffle.socialPosts.start,
  props.raffle.socialPosts.lastDay,
]);

const entryState = (entry: RaffleEntry) => {
  if (entry.claimedAt) return t("labels.raffleEntry.states.claimed");
  if (entry.forfeitedAt && entry.wonAt) {
    return t("labels.raffleEntry.states.forfeited");
  }
  if (entry.forfeitedAt) return t("labels.raffleEntry.states.passedOver");
  if (entry.wonAt) return t("labels.raffleEntry.states.winner");
  if (entry.drawPosition) return t("labels.raffleEntry.states.waiting");
  if (props.raffle.drawnAt) return t("labels.raffleEntry.states.notDrawn");

  return "—";
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-raffles' },
        label: t('headlines.admin.raffles.index'),
      },
    ]"
  />
  <Heading hero>
    {{ raffle.title }}
    <HeadingSmall>
      {{ t(`labels.raffle.statuses.${raffle.status}`) }}
      ·
      {{ t("labels.raffle.entriesCountValue", { count: raffle.entriesCount }) }}
    </HeadingSmall>
  </Heading>

  <RaffleOverview :raffle="raffle" />

  <Teleport to="#header-right">
    <template v-if="isDraft">
      <Btn
        class="navigation-header-pinned"
        :to="{ name: 'admin-raffle-edit', params: { id: raffle.id } }"
        data-test="raffle-edit"
      >
        <i class="fa-duotone fa-pen-to-square" />
        {{ t("actions.edit") }}
      </Btn>
      <Btn
        class="navigation-header-pinned"
        :tone="BtnTonesEnum.DANGER"
        :loading="destroyMutation.isPending.value"
        data-test="raffle-delete"
        @click="destroy"
      >
        <i class="fa-duotone fa-trash" />
        {{ t("actions.delete") }}
      </Btn>
    </template>
    <Btn
      v-if="raffle.status === RaffleStatusEnum.CLOSED"
      class="navigation-header-pinned"
      :loading="drawMutation.isPending.value"
      @click="draw"
    >
      <i class="fa-duotone fa-shuffle" />
      {{ t("actions.raffle.draw") }}
    </Btn>
  </Teleport>

  <Alert
    v-if="raffle.drawnAt"
    :title="t('labels.raffle.drawnInfo')"
    :variant="AlertVariantsEnum.NEUTRAL"
  >
    {{
      t("labels.raffle.drawnBy", {
        date: l(raffle.drawnAt, "datetime.formats.short"),
        admin: raffle.drawnBy || "—",
      })
    }}
  </Alert>

  <Alert
    v-if="winner"
    :title="t('labels.raffle.currentWinner', { username: winner.username })"
    :variant="
      winner.prizeMailStatus === 'bounced' ||
      winner.claimMailStatus === 'bounced'
        ? AlertVariantsEnum.WARNING
        : AlertVariantsEnum.INFO
    "
  >
    <p v-if="winner.claimedAt">
      {{
        t("labels.raffle.claimedInfo", {
          date: l(winner.claimedAt, "datetime.formats.short"),
          mail: mailState(winner.prizeMailStatus),
        })
      }}
    </p>
    <p v-else>
      {{
        t("labels.raffle.claimPending", {
          date: l(winner.claimDeadlineAt as string, "datetime.formats.short"),
          mail: mailState(winner.claimMailStatus),
          email: winner.maskedEmail || "—",
        })
      }}
    </p>
  </Alert>

  <section class="raffle-social-posts">
    <h2 class="raffle-social-posts__title">
      {{ t("labels.raffle.socialPosts") }}
    </h2>
    <AnnouncementManualPosts :posts="socialPosts" />
  </section>

  <FilteredList
    name="admin-raffle-entries"
    :records="entries?.items || []"
    :async-status="asyncStatus"
    hide-loading
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="entries?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
      >
        <template #col-drawPosition="{ record }">
          {{ record.drawPosition ?? "—" }}
        </template>
        <template #col-username="{ record }">
          {{ record.username }}
          <i
            v-if="record.accountDeleted"
            v-tooltip="t('labels.raffleEntry.accountDeleted')"
            class="fa-duotone fa-user-slash"
          />
        </template>
        <template #col-conditionsAcceptedAt="{ record }">
          {{ l(record.conditionsAcceptedAt, "datetime.formats.short") }}
          <small>({{ record.conditionsVersion }})</small>
        </template>
        <template #col-state="{ record }">
          {{ entryState(record) }}
        </template>
        <template #col-mail="{ record }">
          <span v-if="record.claimMailStatus">
            {{ t("labels.raffleEntry.claimMail") }}:
            {{ mailState(record.claimMailStatus) }}
          </span>
          <span v-if="record.prizeMailStatus">
            · {{ t("labels.raffleEntry.prizeMail") }}:
            {{ mailState(record.prizeMailStatus) }}
          </span>
        </template>
      </BaseTable>
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="entries"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.raffle-social-posts {
  margin-bottom: 24px;
}

.raffle-social-posts__title {
  font-size: 1.1rem;
}
</style>
