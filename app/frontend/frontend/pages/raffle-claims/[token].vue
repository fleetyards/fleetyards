<script lang="ts">
export default {
  name: "RaffleClaimPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import { useClaimRafflePrize } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { displaySuccess } = useAppNotifications();

const error = ref<string>();

const claimMutation = useClaimRafflePrize();

// Claimed on arrival: following the link from the mail is the claim. A second
// visit answers the same, and the code only ever travels by mail. A link that
// fails stays on the page, since the reader has nowhere better to go.
onMounted(async () => {
  await claimMutation
    .mutateAsync({ data: { token: route.params.token as string } })
    .then((claim) => {
      displaySuccess({
        text: t("raffles.claim.success", { raffle: claim.raffleTitle }),
      });
      void router.replace({ name: "raffle", params: { id: claim.raffleId } });
    })
    .catch((failure) => {
      error.value =
        failure.response?.data?.message || t("raffles.claim.failed");
    });
});
</script>

<template>
  <Heading hero>{{ t("raffles.claim.title") }}</Heading>

  <p v-if="claimMutation.isPending.value" data-test="raffle-claim-pending">
    {{ t("raffles.claim.pending") }}
  </p>

  <Alert
    v-else-if="error"
    :title="t('raffles.claim.failedTitle')"
    :variant="AlertVariantsEnum.DANGER"
    data-test="raffle-claim-error"
  >
    {{ error }}
  </Alert>
</template>
