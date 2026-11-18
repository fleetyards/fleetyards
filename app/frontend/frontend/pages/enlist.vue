<script lang="ts">
export default {
  name: "EnlistPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  RSI_ENLIST_URL,
  RSI_REFERRAL_CODE,
} from "@/frontend/utils/rsiReferral";

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const steps = ["signUp", "package", "bonus"] as const;

const copyCode = async () => {
  try {
    await navigator.clipboard.writeText(RSI_REFERRAL_CODE);
    displaySuccess({ text: t("messages.copyReferralCode.success") });
  } catch {
    displayAlert({ text: t("messages.copyReferralCode.failure") });
  }
};
</script>

<template>
  <div class="enlist-page" data-test="enlist">
    <Heading hero>{{ t("headlines.enlist") }}</Heading>

    <Panel inset>
      <div class="enlist-page__body">
        <p class="enlist-page__lede">{{ t("texts.enlist.lede") }}</p>

        <div class="enlist-page__code">
          <span class="enlist-page__code-label">
            {{ t("labels.enlist.code") }}
          </span>
          <code data-test="enlist-code">{{ RSI_REFERRAL_CODE }}</code>
          <Btn
            :variant="BtnVariantsEnum.GHOST"
            :size="BtnSizesEnum.SM"
            data-test="enlist-copy"
            @click="copyCode"
          >
            <i class="fa-light fa-copy" />
            {{ t("actions.copy") }}
          </Btn>
        </div>

        <ol class="enlist-page__steps">
          <li v-for="step in steps" :key="step">
            {{ t(`texts.enlist.steps.${step}`) }}
          </li>
        </ol>

        <div class="enlist-page__actions">
          <Btn
            :href="RSI_ENLIST_URL"
            :size="BtnSizesEnum.LG"
            data-test="enlist-sign-up"
          >
            {{ t("actions.enlist.signUp") }}
            <i class="fa-light fa-arrow-up-right-from-square" />
          </Btn>
        </div>

        <p class="enlist-page__note">{{ t("texts.enlist.note") }}</p>
      </div>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.enlist-page {
  max-width: 760px;
  margin-inline: auto;
}

.enlist-page__body {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding-bottom: 20px;
}

.enlist-page__lede {
  margin: 0;
  font-size: 1.0625rem;
  line-height: 1.6;
}

.enlist-page__code {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px 14px;

  code {
    padding: 6px 12px;
    color: var(--color-lifted);
    font-family: ui-monospace, "SFMono-Regular", menlo, monospace;
    font-size: 1.25rem;
    letter-spacing: 0.04em;
    background: var(--color-surface, rgb(39 43 48 / 90%));
    border: 1px solid var(--color-edge-soft);
    border-radius: var(--radius-surface-slim);
  }
}

.enlist-page__code-label {
  color: var(--color-text-dim);
  font-size: 0.75rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.enlist-page__steps {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding-left: 1.25rem;
  line-height: 1.5;
  list-style: decimal;
}

.enlist-page__actions {
  display: flex;
}

.enlist-page__note {
  margin: 0;
  color: var(--color-text-dim);
  font-size: 0.82rem;
  line-height: 1.45;
}
</style>
