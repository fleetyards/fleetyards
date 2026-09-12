<script lang="ts">
export default {
  name: "TourPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import PayoutLedger from "@/frontend/components/Payouts/PayoutLedger/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import copyText from "@/shared/utils/CopyText";
import { useTour } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";

const { t, l } = useI18n();
const route = useRoute();
const sessionStore = useSessionStore();
const { displaySuccess, displayAlert } = useAppNotifications();

const slug = computed(() => String(route.params.slug));

const { data: tour } = useTour(slug);

// The organiser is the only one who manages the tour; everyone on it may record
// what they spent. The API enforces both -- this only decides what is offered.
const isOrganiser = computed(
  () => tour.value?.createdBy?.id === sessionStore.currentUser?.id,
);

const inviteUrl = computed(() => {
  if (!tour.value?.inviteToken) {
    return null;
  }

  return `${window.location.origin}/tools/tours/join/${tour.value.inviteToken}/`;
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

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "tools" }, label: t("nav.tools.index") },
  { to: { name: "tours" }, label: t("nav.tools.tours") },
  { label: tour.value?.title ?? "" },
]);

const { updateMetaInfo } = useMetaInfo();

watch(
  () => tour.value?.title,
  (title) => {
    if (title) {
      updateMetaInfo({ title });
    }
  },
  { immediate: true },
);
</script>

<template>
  <section v-if="tour" class="container">
    <BreadCrumbs :crumbs="crumbs" />

    <Heading>
      {{ tour.title }}
      <template #actions-right>
        <Btn
          v-if="isOrganiser && inviteUrl"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.GHOST"
          data-test="tour-copy-invite"
          @click="onCopyInvite"
        >
          {{ t("actions.payouts.copyInvite") }}
        </Btn>
      </template>
    </Heading>

    <div class="tour-meta">
      <Pill>
        {{
          t(`labels.payouts.${tour.status === "settled" ? "settled" : "open"}`)
        }}
      </Pill>
      <span v-if="tour.startsAt" class="tour-meta__date">
        {{ l(tour.startsAt) }}
      </span>
    </div>

    <p v-if="tour.description" class="tour-description">
      {{ tour.description }}
    </p>

    <PayoutLedger
      v-if="tour.payoutLedgerId"
      :payout-ledger-id="tour.payoutLedgerId"
      :manageable="isOrganiser"
      :contributable="true"
    />
  </section>
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
