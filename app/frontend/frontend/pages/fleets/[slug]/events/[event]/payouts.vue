<script lang="ts">
export default {
  name: "FleetEventPayoutsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PayoutLedger from "@/frontend/components/Payouts/PayoutLedger/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { checkAccess } from "@/shared/utils/Access";
import {
  useFleetEventPayoutLedger,
  useCreateFleetEventPayoutLedger as useCreateFleetEventPayoutLedgerMutation,
} from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import type { ApiError } from "@/shared/types/api-error";

// Handed down by the events shell, which already gates this whole subtree on
// the mission-builder flag -- an event ledger presupposes events.
type Props = {
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const { displayAlert } = useAppNotifications();

const fleetSlug = computed(() => String(route.params.slug));
const eventSlug = computed(() => String(route.params.event));

const { data: ledger, refetch } = useFleetEventPayoutLedger(
  fleetSlug,
  eventSlug,
  // A 404 here is the normal "no ledger opened yet" state, not an error worth
  // retrying or reporting.
  { query: { retry: false } },
);

const canManage = computed(() =>
  checkAccess(props.resourceAccess, ["fleet:manage", "fleet:payouts:manage"]),
);

const canContribute = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:payouts:manage",
    "fleet:payouts:create",
  ]),
);

const opening = ref(false);

const createMutation = useCreateFleetEventPayoutLedgerMutation();

const onOpenLedger = async () => {
  opening.value = true;

  await createMutation
    .mutateAsync({
      fleetSlug: fleetSlug.value,
      fleetEventSlug: eventSlug.value,
      data: {},
    })
    .then(() => {
      void refetch();
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      opening.value = false;
    });
};

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet-events", params: { slug: fleetSlug.value } },
    label: t("nav.fleets.events.index"),
  },
  {
    to: {
      name: "fleet-event",
      params: { slug: fleetSlug.value, event: eventSlug.value },
    },
    label: t("nav.fleets.events.index"),
  },
  { label: t("nav.fleets.events.payouts") },
]);
</script>

<template>
  <section class="container">
    <BreadCrumbs :crumbs="crumbs" />

    <Heading>{{ t("headlines.payouts.index") }}</Heading>

    <Panel v-if="!ledger">
      <PanelBody>
        <p class="fleet-event-payouts__empty">
          {{ t("empty.payouts.entries") }}
        </p>
        <Btn
          v-if="canManage"
          :loading="opening"
          :size="BtnSizesEnum.LG"
          data-test="payout-open-ledger"
          @click="onOpenLedger"
        >
          {{ t("actions.payouts.openLedger") }}
        </Btn>
      </PanelBody>
    </Panel>

    <PayoutLedger
      v-else
      :payout-ledger-id="ledger.id"
      :manageable="canManage"
      :contributable="canContribute"
    />
  </section>
</template>

<style lang="scss" scoped>
.fleet-event-payouts__empty {
  color: var(--color-muted, #999);
  margin-bottom: 16px;
}
</style>
