<script lang="ts">
export default {
  name: "OauthApplicationState",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  state: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

// Awaiting review is a warning rather than neutral: the application does not
// work yet, and that is something the reader has to act on or wait out.
const variant = computed(() => {
  switch (props.state) {
    case "approved":
      return PillVariantsEnum.SUCCESS;
    case "rejected":
      return PillVariantsEnum.DANGER;
    default:
      return PillVariantsEnum.WARNING;
  }
});

const label = computed(() => {
  switch (props.state) {
    case "approved":
      return t("labels.oauthApplications.stateApproved");
    case "rejected":
      return t("labels.oauthApplications.stateRejected");
    default:
      return t("labels.oauthApplications.statePending");
  }
});
</script>

<template>
  <Pill :variant="variant" uppercase>{{ label }}</Pill>
</template>
