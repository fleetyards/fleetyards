<script lang="ts">
export default {
  name: "FleetFidClaimActionItems",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import {
  type AdminFleetFidClaim,
  getFleetFidClaimsQueryKey,
  useCancelFleetFidClaim,
  useUpdateFleetFidClaim,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";

type Props = {
  claim: AdminFleetFidClaim;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();

const { displayConfirm, displaySuccess, displayAlert } = useAppNotifications();

const queryClient = useQueryClient();

const invalidateClaims = () =>
  queryClient.invalidateQueries({
    queryKey: getFleetFidClaimsQueryKey(),
  });

const updateMutation = useUpdateFleetFidClaim({
  mutation: { onSettled: invalidateClaims },
});

const cancelMutation = useCancelFleetFidClaim({
  mutation: { onSettled: invalidateClaims },
});

const endNow = () => {
  displayConfirm({
    text: t("messages.confirm.adminFleetFidClaim.endNow"),
    onConfirm: async () => {
      await updateMutation
        .mutateAsync({
          id: props.claim.id,
          data: { endsAt: new Date().toISOString() },
        })
        .then(() => {
          displaySuccess({ text: t("messages.fleet.fidClaim.endNow.success") });
        })
        .catch((error) => {
          displayAlert({
            text:
              validationErrorFrom(error).message ||
              t("messages.fleet.fidClaim.endNow.failure"),
          });
        });
    },
  });
};

const cancel = () => {
  displayConfirm({
    text: t("messages.confirm.adminFleetFidClaim.cancel"),
    onConfirm: async () => {
      await cancelMutation
        .mutateAsync({ id: props.claim.id })
        .then(() => {
          displaySuccess({ text: t("messages.fleet.fidClaim.cancel.success") });
        })
        .catch((error) => {
          displayAlert({
            text:
              validationErrorFrom(error).message ||
              t("messages.fleet.fidClaim.cancel.failure"),
          });
        });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.fleet.fidClaim.endNow')"
    :aria-label="t('actions.fleet.fidClaim.endNow')"
    data-test="fleet-fid-claim-end-now"
    @click="endNow"
  >
    <i class="fa-duotone fa-forward-fast" />
    <span v-if="withLabels">{{ t("actions.fleet.fidClaim.endNow") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.fleet.fidClaim.cancel')"
    :aria-label="t('actions.fleet.fidClaim.cancel')"
    data-test="fleet-fid-claim-cancel"
    @click="cancel"
  >
    <i class="fa-duotone fa-ban" />
    <span v-if="withLabels">{{ t("actions.fleet.fidClaim.cancel") }}</span>
  </Btn>
</template>
