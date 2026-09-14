<script lang="ts">
export default {
  name: "PayoutsTourDetails",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import PayoutLedger from "@/frontend/components/Payouts/PayoutLedger/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import copyText from "@/shared/utils/CopyText";
import type { Tour } from "@/services/fyApi";

type Props = {
  tour: Tour;
  // A fleet's payout managers manage a tour they never organised; on a
  // standalone one only the organiser does. The API enforces both -- this only
  // decides what is offered.
  manageable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { manageable: false });

const { t, l } = useI18n();
const sessionStore = useSessionStore();
const { displaySuccess, displayAlert } = useAppNotifications();

const isOrganiser = computed(
  () => props.tour.createdBy?.id === sessionStore.currentUser?.id,
);

const canManage = computed(() => isOrganiser.value || props.manageable);

// The join page is the same one either way -- a tour is joined by its token,
// not through whichever list it was found in.
const inviteUrl = computed(() => {
  if (!props.tour.inviteToken) {
    return null;
  }

  return `${window.location.origin}/tools/tours/join/${props.tour.inviteToken}/`;
});

const onCopyInvite = async () => {
  if (!inviteUrl.value) {
    return;
  }

  await copyText(inviteUrl.value)
    .then(() => {
      displaySuccess({ text: t("messages.payouts.inviteCopied") });
    })
    .catch(() => {
      displayAlert({ text: inviteUrl.value as string });
    });
};
</script>

<template>
  <Teleport to="#header-right">
    <Btn
      v-if="inviteUrl"
      :aria-label="t('actions.payouts.copyInvite')"
      data-test="tour-copy-invite"
      mobile-icon-only
      @click="onCopyInvite"
    >
      <i class="fa-light fa-link" />
      <span>{{ t("actions.payouts.copyInvite") }}</span>
    </Btn>
  </Teleport>

  <div class="tour-meta">
    <Pill>
      {{
        t(`labels.payouts.${tour.status === "settled" ? "settled" : "open"}`)
      }}
    </Pill>
    <span v-if="tour.startsAt" class="tour-meta__date">
      {{ l(tour.startsAt, "datetime.formats.dateTime") }}
    </span>
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
  />
</template>

<style lang="scss" scoped>
.tour-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.tour-meta__date {
  color: var(--color-muted, #999);
  font-size: 12px;
}

.tour-description {
  color: var(--color-muted, #999);
  margin-bottom: 16px;
}
</style>
