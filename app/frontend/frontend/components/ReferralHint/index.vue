<script lang="ts">
export default {
  name: "ReferralHint",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  RSI_ENLIST_URL,
  RSI_REFERRAL_CODE,
} from "@/frontend/utils/rsiReferral";

const { t } = useI18n();
</script>

<template>
  <p class="referral-hint" data-test="referral-hint">
    {{ t("texts.referral.hint") }}
    <a
      :href="RSI_ENLIST_URL"
      class="referral-hint__code"
      target="_blank"
      rel="noopener"
      data-test="referral-hint-code"
    >
      <b>{{ RSI_REFERRAL_CODE }}</b>
    </a>
  </p>
</template>

<style lang="scss" scoped>
.referral-hint {
  margin: var(--referral-hint-margin, 0);
  color: var(--referral-hint-color, inherit);
  font-size: 0.82rem;
  line-height: 1.45;
}

.referral-hint__code {
  font-family: ui-monospace, "SFMono-Regular", menlo, monospace;
  white-space: nowrap;
}
</style>
