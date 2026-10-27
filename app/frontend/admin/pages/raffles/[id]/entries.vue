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
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  type Raffle,
  type RaffleEntry,
  RaffleStatusEnum,
  useRaffleEntries,
  useDrawRaffle,
  useSendRaffleEntryVerification,
  useClaimRaffleEntry,
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
const sendVerificationMutation = useSendRaffleEntryVerification({
  mutation: { onSettled: invalidate },
});
const claimMutation = useClaimRaffleEntry({
  mutation: { onSettled: invalidate },
});

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

const sendVerification = async (entry: RaffleEntry) => {
  await sendVerificationMutation
    .mutateAsync({ raffleId: props.raffle.id, id: entry.id })
    .then((response) => {
      displaySuccess({ text: response.message });
    })
    .catch((error) => {
      displayAlert({ text: error.response?.data?.message });
    });
};

const verificationCode = ref("");
const handedOverCode = ref<string>();

const claim = async (entry: RaffleEntry) => {
  await claimMutation
    .mutateAsync({
      raffleId: props.raffle.id,
      id: entry.id,
      data: { verificationCode: verificationCode.value },
    })
    .then((response) => {
      handedOverCode.value = response.code;
      verificationCode.value = "";
      displaySuccess({ text: t("messages.raffleEntry.claimed") });
    })
    .catch((error) => {
      displayAlert({ text: error.response?.data?.message });
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
];

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

  <Teleport to="#header-right">
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
    v-if="handedOverCode"
    :title="t('labels.raffle.handOverCode')"
    :variant="AlertVariantsEnum.SUCCESS"
    dismissible
    @dismiss="handedOverCode = undefined"
  >
    <code class="raffle-gift-code">{{ handedOverCode }}</code>
  </Alert>

  <Alert
    v-if="winner && !winner.claimedAt"
    :title="t('labels.raffle.currentWinner', { username: winner.username })"
    :variant="
      winner.accountDeleted ? AlertVariantsEnum.WARNING : AlertVariantsEnum.INFO
    "
  >
    <p>
      {{
        t("labels.raffle.claimDeadline", {
          date: l(winner.claimDeadlineAt as string, "datetime.formats.short"),
        })
      }}
    </p>
    <p v-if="winner.accountDeleted">
      {{
        t("labels.raffle.accountDeletedInfo", {
          email: winner.maskedEmail || "—",
        })
      }}
    </p>
    <p v-else>{{ t("labels.raffle.selfClaimInfo") }}</p>

    <template v-if="winner.claimable && winner.maskedEmail">
      <Btn
        :loading="sendVerificationMutation.isPending.value"
        @click="sendVerification(winner)"
      >
        <i class="fa-duotone fa-envelope" />
        {{ t("actions.raffle.sendVerification") }}
      </Btn>
      <form
        v-if="winner.verificationSentAt"
        class="raffle-verification"
        @submit.prevent="claim(winner)"
      >
        <FormInput
          v-model="verificationCode"
          name="verificationCode"
          translation-key="raffleEntry.verificationCode"
          autocomplete="one-time-code"
        />
        <Btn
          type="submit"
          :disabled="verificationCode.length < 6"
          :loading="claimMutation.isPending.value"
        >
          <i class="fa-duotone fa-gift" />
          {{ t("actions.raffle.handOver") }}
        </Btn>
      </form>
    </template>
  </Alert>

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
.raffle-gift-code {
  font-size: 1.25rem;
  letter-spacing: 0.1em;
  user-select: all;
}

.raffle-verification {
  display: flex;
  gap: 8px;
  align-items: flex-end;
  margin-top: 12px;
}
</style>
