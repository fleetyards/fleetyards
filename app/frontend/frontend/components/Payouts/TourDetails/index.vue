<script lang="ts">
export default {
  name: "PayoutsTourDetails",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useQueryClient } from "@tanstack/vue-query";
import Pill from "@/shared/components/base/Pill/index.vue";
import PayoutLedger from "@/frontend/components/Payouts/PayoutLedger/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import { usePayoutCurrencyOptions } from "@/frontend/composables/usePayoutCurrency";
import {
  useCreateTourJoinRequest as useCreateTourJoinRequestMutation,
  useDestroyTourJoinRequest as useDestroyTourJoinRequestMutation,
  useUpdateTour as useUpdateTourMutation,
  useArchiveTour as useArchiveTourMutation,
  useUnarchiveTour as useUnarchiveTourMutation,
  useDestroyTour as useDestroyTourMutation,
} from "@/services/fyApi";
import type { Tour, TourCurrencyEnum } from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  tour: Tour;
  // A fleet's payout managers manage a tour they never organised; on a
  // standalone one only the organiser does. The API enforces both -- this only
  // decides what is offered.
  manageable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { manageable: false });

// Asking, withdrawing and being approved all change what the tour payload
// says about the viewer, and the page owns that query.
const emit = defineEmits<{ reload: [] }>();

const { t, l } = useI18n();
const comlink = useComlink();
const sessionStore = useSessionStore();

const router = useRouter();
const { displaySuccess, displayAlert } = useAppNotifications();

const isOrganiser = computed(
  () => props.tour.createdBy?.id === sessionStore.currentUser?.id,
);

const canManage = computed(() => isOrganiser.value || props.manageable);

const queryClient = useQueryClient();

// Archiving or deleting moves the tour between lists the reader is about to
// go back to.
const invalidateTourLists = () =>
  queryClient.invalidateQueries({
    predicate: (query) => {
      const [key] = query.queryKey;

      return typeof key === "string" && key.endsWith("/tours");
    },
  });

const currencyOptions = usePayoutCurrencyOptions();

// Once settled, the transfers people pay against are frozen in a currency.
const currencyEditable = computed(
  () => canManage.value && props.tour.status === "open" && !props.tour.archived,
);

const updateTourMutation = useUpdateTourMutation();

const onCurrency = async (currency: TourCurrencyEnum) => {
  if (currency === props.tour.currency) {
    return;
  }

  await updateTourMutation
    .mutateAsync({ slug: props.tour.slug, data: { currency } })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.currencyUpdated") });
      emit("reload");
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    });
};

const archiveMutation = useArchiveTourMutation();
const unarchiveMutation = useUnarchiveTourMutation();
const destroyMutation = useDestroyTourMutation();

const archiving = ref(false);

const onArchive = async () => {
  archiving.value = true;

  const mutation = props.tour.archived ? unarchiveMutation : archiveMutation;

  await mutation
    .mutateAsync({ slug: props.tour.slug })
    .then(() => {
      displaySuccess({
        text: props.tour.archived
          ? t("messages.payouts.tourUnarchived")
          : t("messages.payouts.tourArchived"),
      });
      void invalidateTourLists();
      emit("reload");
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      archiving.value = false;
    });
};

const deleting = ref(false);

const onDelete = async () => {
  deleting.value = true;

  await destroyMutation
    .mutateAsync({ slug: props.tour.slug })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.tourDeleted") });
      void invalidateTourLists();
      void router.push(
        props.tour.fleet
          ? { name: "fleet-tours", params: { slug: props.tour.fleet.slug } }
          : { name: "tours" },
      );
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      deleting.value = false;
    });
};

// Asking onto the tour only exists on a fleet's: a standalone one is not
// listed anywhere a stranger could have found it, so its link is the way in.
const askable = computed(
  () =>
    !!props.tour.fleet &&
    props.tour.status === "open" &&
    !props.tour.archived &&
    !props.tour.participating &&
    !props.tour.joinRequestPending,
);

const withdrawable = computed(
  () => !!props.tour.fleet && !!props.tour.joinRequestId,
);

const createJoinRequestMutation = useCreateTourJoinRequestMutation();
const destroyJoinRequestMutation = useDestroyTourJoinRequestMutation();

const asking = ref(false);

const onAsk = async () => {
  asking.value = true;

  await createJoinRequestMutation
    .mutateAsync({ tourSlug: props.tour.slug })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.joinRequested") });
      emit("reload");
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      asking.value = false;
    });
};

const onWithdraw = async () => {
  if (!props.tour.joinRequestId) {
    return;
  }

  asking.value = true;

  await destroyJoinRequestMutation
    .mutateAsync({ tourSlug: props.tour.slug, id: props.tour.joinRequestId })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.joinRequestWithdrawn") });
      emit("reload");
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      asking.value = false;
    });
};

// The ledger reaches the page over its own channel, but the viewer's standing
// on the tour -- whether they are on it, and whether their ask is still
// unanswered -- rides on the tour payload, which that channel says nothing
// about. Without this an approved ask still reads as pending until a reload.
const ledgerChangedComlink = ref();

onMounted(() => {
  ledgerChangedComlink.value = comlink.on("payout-ledger-changed", () => {
    emit("reload");
  });
});

onBeforeUnmount(() => {
  ledgerChangedComlink.value?.();
});

// The join page is the same one either way -- a tour is joined by its token,
// not through whichever list it was found in.
const inviteUrl = computed(() => {
  if (!props.tour.inviteToken) {
    return null;
  }

  return `${window.location.origin}/tools/tours/join/${props.tour.inviteToken}/`;
});

// Someone who may invite shares the link that lets the recipient join; anyone
// else can only point at the page, which opens for those already on the tour
// or in its fleet.
const shareUrl = computed(() => {
  if (inviteUrl.value) {
    return inviteUrl.value;
  }

  const location = props.tour.fleet
    ? {
        name: "fleet-tour",
        params: { slug: props.tour.fleet.slug, tour: props.tour.slug },
      }
    : { name: "tour", params: { slug: props.tour.slug } };

  return new URL(
    router.resolve(location).href,
    window.location.origin,
  ).toString();
});
</script>

<template>
  <Teleport to="#header-right">
    <Btn
      v-if="askable"
      :size="BtnSizesEnum.MD"
      :loading="asking"
      :aria-label="t('actions.payouts.askToJoin')"
      data-test="tour-ask-to-join"
      mobile-icon-only
      @click="onAsk"
    >
      <i class="fa-light fa-hand" />
      <span>{{ t("actions.payouts.askToJoin") }}</span>
    </Btn>

    <Btn
      v-if="withdrawable"
      :size="BtnSizesEnum.MD"
      :loading="asking"
      :aria-label="t('actions.payouts.withdrawJoinRequest')"
      data-test="tour-withdraw-join-request"
      mobile-icon-only
      @click="onWithdraw"
    >
      <i class="fa-light fa-hand" />
      <span>{{ t("actions.payouts.withdrawJoinRequest") }}</span>
    </Btn>

    <!-- One button, whichever it does: a tour nobody else is on can go, one
         with other people's money on it is only put away. -->
    <Btn
      v-if="canManage && tour.deletable && !tour.archived"
      :size="BtnSizesEnum.MD"
      :tone="BtnTonesEnum.DANGER"
      :loading="deleting"
      :confirm="t('messages.payouts.deleteTourConfirm')"
      :aria-label="t('actions.payouts.deleteTour')"
      :title="t('texts.payouts.deleteHint')"
      data-test="tour-delete"
      mobile-icon-only
      @click="onDelete"
    >
      <i class="fa-light fa-trash" />
      <span>{{ t("actions.payouts.deleteTour") }}</span>
    </Btn>
    <Btn
      v-else-if="canManage"
      :size="BtnSizesEnum.MD"
      :loading="archiving"
      :confirm="
        tour.archived ? undefined : t('messages.payouts.archiveTourConfirm')
      "
      :aria-label="
        tour.archived
          ? t('actions.payouts.unarchiveTour')
          : t('actions.payouts.archiveTour')
      "
      data-test="tour-archive"
      mobile-icon-only
      @click="onArchive"
    >
      <i
        :class="
          tour.archived ? 'fa-light fa-box-open' : 'fa-light fa-box-archive'
        "
      />
      <span>{{
        tour.archived
          ? t("actions.payouts.unarchiveTour")
          : t("actions.payouts.archiveTour")
      }}</span>
    </Btn>

    <ShareBtn
      :url="shareUrl"
      :title="tour.title"
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      data-test="tour-share"
    />
  </Teleport>

  <div class="tour-meta">
    <Pill>
      {{
        t(`labels.payouts.${tour.status === "settled" ? "settled" : "open"}`)
      }}
    </Pill>
    <Pill v-if="tour.archived" data-test="tour-archived">
      {{ t("labels.payouts.archived") }}
    </Pill>
    <Pill v-if="tour.joinRequestPending" data-test="tour-join-request-pending">
      {{ t("labels.payouts.joinRequestPending") }}
    </Pill>
    <span v-if="tour.startsAt" class="tour-meta__date">
      {{ l(tour.startsAt, "datetime.formats.dateTime") }}
    </span>
    <BaseSelect
      v-if="currencyEditable"
      :model-value="tour.currency"
      name="currency"
      class="tour-meta__currency"
      :options="currencyOptions"
      :nullable="false"
      unsorted
      :searchable="true"
      :label="t('labels.payouts.currency')"
      :no-label="true"
      inline
      data-test="tour-currency"
      @update:model-value="(value) => onCurrency(value as TourCurrencyEnum)"
    />
  </div>

  <p v-if="tour.description" class="tour-description">
    {{ tour.description }}
  </p>

  <!-- Everyone on a tour accounts for their own money, so there is no privilege
       to read here. A fleet's payout readers reach a tour they never joined,
       and the ledger withholds the controls from them because they have no
       participant row to record against. -->
  <PayoutLedger
    v-if="tour.payoutLedgerId"
    :payout-ledger-id="tour.payoutLedgerId"
    :manageable="canManage"
    :contributable="true"
    :tour-slug="tour.fleet ? tour.slug : undefined"
    :currency="tour.currency"
  />
</template>

<style lang="scss" scoped>
.tour-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.tour-meta__currency {
  margin-left: auto;
  min-width: 200px;

  // Wrapped onto a line of its own anyway, where pushed right it read as
  // floating.
  @media (max-width: 576px) {
    flex-basis: 100%;
    margin-left: 0;
  }
}

.tour-meta__date {
  color: var(--color-muted, #7a8288);
  font-size: 12px;
}

.tour-description {
  color: var(--color-muted, #7a8288);
  margin-bottom: 16px;
}
</style>
