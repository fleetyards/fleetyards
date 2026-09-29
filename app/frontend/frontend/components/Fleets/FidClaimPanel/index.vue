<script lang="ts">
export default {
  name: "FleetFidClaimPanel",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type FleetFidClaimStatus,
  FleetFidClaimAvailabilityEnum,
  getFleetFidClaimQueryKey,
  useCreateFleetFidClaim,
  useDestroyFleetFidClaim,
  useFleetFidClaim,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const queryClient = useQueryClient();

const { data: claimStatus, refetch } = useFleetFidClaim(() => props.fleet.slug);

// Verifying happens in a modal and a new FID is saved by the form, and both
// change what the fleet can claim.
watch(
  () => [props.fleet.rsiVerified, props.fleet.fid],
  () => refetch(),
);

const availability = computed(() => claimStatus.value?.availability);

const outgoingClaim = computed(() => claimStatus.value?.outgoing);

const createMutation = useCreateFleetFidClaim();

const destroyMutation = useDestroyFleetFidClaim();

const storeStatus = (status: FleetFidClaimStatus) => {
  queryClient.setQueryData(getFleetFidClaimQueryKey(props.fleet.slug), status);
};

// Confirmed first: the holder hears of it the moment it is opened.
const claim = () => {
  displayConfirm({
    text: t("messages.confirm.fleetFidClaim.create", {
      fid: claimStatus.value?.fid,
    }),
    onConfirm: async () => {
      await createMutation
        .mutateAsync({ fleetSlug: props.fleet.slug })
        .then((status) => {
          storeStatus(status);

          displaySuccess({
            text: t("messages.fleet.fidClaim.create.success"),
          });
        })
        .catch((error) => {
          displayAlert({
            text:
              validationErrorFrom(error).message ||
              t("messages.fleet.fidClaim.create.failure"),
          });
        });
    },
  });
};

const withdraw = async () => {
  await destroyMutation
    .mutateAsync({ fleetSlug: props.fleet.slug })
    .then((status) => {
      storeStatus(status);

      displaySuccess({ text: t("messages.fleet.fidClaim.destroy.success") });
    })
    .catch((error) => {
      displayAlert({
        text:
          validationErrorFrom(error).message ||
          t("messages.fleet.fidClaim.destroy.failure"),
      });
    });
};
</script>

<template>
  <Alert
    v-if="outgoingClaim"
    :variant="AlertVariantsEnum.INFO"
    :title="t('labels.fleet.fidClaim.pendingTitle', { fid: outgoingClaim.fid })"
    data-test="fleet-fid-claim-pending"
  >
    {{
      t("labels.fleet.fidClaim.pending", {
        fid: outgoingClaim.fid,
        holder: outgoingClaim.holderName ?? outgoingClaim.fid,
        date: l(outgoingClaim.endsAt, "datetime.formats.date"),
      })
    }}
    <template #actions>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :loading="destroyMutation.isPending.value"
        data-test="fleet-fid-claim-withdraw"
        @click="withdraw"
      >
        {{ t("actions.fleet.fidClaim.withdraw") }}
      </Btn>
    </template>
  </Alert>
  <Alert
    v-else-if="availability === FleetFidClaimAvailabilityEnum.CLAIMABLE"
    :variant="AlertVariantsEnum.INFO"
    :title="
      t('labels.fleet.fidClaim.claimableTitle', { fid: claimStatus?.fid })
    "
    data-test="fleet-fid-claim-claimable"
  >
    {{ t("labels.fleet.fidClaim.claimable", { fid: claimStatus?.fid }) }}
    <template #actions>
      <Btn
        :size="BtnSizesEnum.SM"
        :loading="createMutation.isPending.value"
        data-test="fleet-fid-claim-create"
        @click="claim"
      >
        {{ t("actions.fleet.fidClaim.claim", { fid: claimStatus?.fid }) }}
      </Btn>
    </template>
  </Alert>
  <Alert
    v-else-if="availability === FleetFidClaimAvailabilityEnum.AVAILABLE"
    :variant="AlertVariantsEnum.SUCCESS"
    :title="
      t('labels.fleet.fidClaim.availableTitle', { fid: claimStatus?.fid })
    "
    data-test="fleet-fid-claim-available"
  >
    {{ t("labels.fleet.fidClaim.available", { fid: claimStatus?.fid }) }}
  </Alert>
</template>
