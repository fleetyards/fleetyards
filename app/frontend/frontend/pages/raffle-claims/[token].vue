<script lang="ts">
export default {
  name: "RaffleClaimPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import { type RaffleClaim, useClaimRafflePrize } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
const route = useRoute();

const claim = ref<RaffleClaim>();
const error = ref<string>();

const claimMutation = useClaimRafflePrize();

// Claimed on arrival: following the link from the mail is the claim. A second
// visit answers the same, and the code only ever travels by mail.
onMounted(async () => {
  await claimMutation
    .mutateAsync({ data: { token: route.params.token as string } })
    .then((response) => {
      claim.value = response;
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
    v-else-if="claim"
    :title="t('raffles.claim.successTitle')"
    :variant="AlertVariantsEnum.SUCCESS"
    data-test="raffle-claim-success"
  >
    <p>{{ t("raffles.claim.success", { raffle: claim.raffleTitle }) }}</p>
    <router-link :to="{ name: 'raffle', params: { id: claim.raffleId } }">
      {{ t("raffles.claim.toRaffle") }}
    </router-link>
  </Alert>

  <Alert
    v-else-if="error"
    :title="t('raffles.claim.failedTitle')"
    :variant="AlertVariantsEnum.DANGER"
    data-test="raffle-claim-error"
  >
    {{ error }}
  </Alert>
</template>
