<script lang="ts">
export default {
  name: "SupporterContributionsLinkedViaPill",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { SupporterContributionLinkedViaEnum } from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  linkedVia?: SupporterContributionLinkedViaEnum;
}

const props = defineProps<Props>();

const { t } = useI18n();

// The token is the rule worth picking out of a column: it is the one a donor
// took a deliberate step for, and the one an admin goes looking for. A Patreon
// sign-in is the strongest link there is, so it reads as settled. The remaining
// two ask nothing of the reader and stay quiet.
const variant = computed(() => {
  switch (props.linkedVia) {
    case SupporterContributionLinkedViaEnum.CLAIM_KEY:
      return PillVariantsEnum.DEFAULT;
    case SupporterContributionLinkedViaEnum.PATREON_ACCOUNT:
      return PillVariantsEnum.SUCCESS;
    default:
      return PillVariantsEnum.NEUTRAL;
  }
});

const icon = computed(() => {
  switch (props.linkedVia) {
    case SupporterContributionLinkedViaEnum.PATREON_ACCOUNT:
      return "fa-brands fa-patreon";
    case SupporterContributionLinkedViaEnum.CLAIM_KEY:
      return "fa-duotone fa-key";
    case SupporterContributionLinkedViaEnum.PAYER_EMAIL:
      return "fa-duotone fa-envelope";
    default:
      return "fa-duotone fa-user-pen";
  }
});
</script>

<template>
  <Pill v-if="props.linkedVia" :variant="variant" data-test="linked-via-pill">
    <i :class="icon" />
    {{ t(`labels.admin.supporterContributions.linkedVia.${props.linkedVia}`) }}
  </Pill>
  <span v-else>—</span>
</template>
