<script lang="ts">
export default {
  name: "SupporterContributionsSourcePill",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  SupporterContributionSourceEnum,
  type NullableSupporterContributionSourceEnum,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  // Nullable: a row nobody stated a platform for is the common case, and it
  // renders as a dash rather than as a value.
  source?: NullableSupporterContributionSourceEnum;
}

const props = defineProps<Props>();

const { t } = useI18n();

// The two platforms an importer writes read as settled, because the row came
// from the platform itself rather than from somebody reading a payment off a
// statement. `other` is the one worth a second look — it is the row whose
// platform nobody stated — so it keeps the attention-carrying tint.
const variant = computed(() => {
  switch (props.source) {
    case SupporterContributionSourceEnum.PATREON:
    case SupporterContributionSourceEnum.KOFI:
      return PillVariantsEnum.SUCCESS;
    case SupporterContributionSourceEnum.OTHER:
      return PillVariantsEnum.DEFAULT;
    default:
      return PillVariantsEnum.NEUTRAL;
  }
});

const icon = computed(() => {
  switch (props.source) {
    case SupporterContributionSourceEnum.PATREON:
      return "fa-brands fa-patreon";
    case SupporterContributionSourceEnum.KOFI:
      return "fa-duotone fa-mug-hot";
    case SupporterContributionSourceEnum.BUYMEACOFFEE:
      return "fa-duotone fa-mug-saucer";
    case SupporterContributionSourceEnum.PAYPAL:
      return "fa-brands fa-paypal";
    default:
      return "fa-duotone fa-hand-holding-heart";
  }
});
</script>

<template>
  <Pill v-if="props.source" :variant="variant" data-test="source-pill">
    <i :class="icon" />
    {{ t(`labels.admin.supporterContributions.source.${props.source}`) }}
  </Pill>
  <span v-else>—</span>
</template>
