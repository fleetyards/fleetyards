<script lang="ts">
export default {
  name: "ExtensionVerificationBlock",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import LoadingDots from "@/shared/components/LoadingDots/index.vue";
import RsiSignedInAs from "@/frontend/components/RsiSignedInAs/index.vue";
import SyncExtensionLinks from "@/frontend/components/SyncExtensionLinks/index.vue";
import { RSI_SIGN_IN_URL } from "@/frontend/lib/rsiLinks";
import { ExtensionVerificationState } from "@/frontend/composables/useExtensionVerification";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // Whose texts: `labels.<scope>.rsiVerification.extension.*`.
  scope: "user" | "fleet";
  testPrefix: string;
  state: ExtensionVerificationState;
  // What is being verified, for the mismatch message.
  target?: string | null;
  rsiHandle?: string;
  error?: string;
  running: boolean;
  checkedByExtension: boolean;
  statusText?: string;
  statusVariant: `${AlertVariantsEnum}`;
  pending: boolean;
  coolingDown: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  target: undefined,
  rsiHandle: undefined,
  error: undefined,
  statusText: undefined,
});

const emit = defineEmits<{ verify: []; redetect: [] }>();

const { t } = useI18n();

// Every text gets what it may name: the handle or SID being verified, and the
// RSI account signed in.
const text = (key: string) =>
  t(`labels.${props.scope}.rsiVerification.extension.${key}`, {
    handle: props.target,
    sid: props.target,
    rsiHandle: props.rsiHandle,
  });

const testId = (name: string) => `${props.testPrefix}-extension-${name}`;
</script>

<template>
  <div class="extension-verification" :data-test="`${testPrefix}-extension`">
    <div class="extension-verification__title">
      {{ text("title") }}
    </div>
    <p
      v-if="state === ExtensionVerificationState.DETECTING"
      class="extension-verification__description"
      :data-test="testId('detecting')"
    >
      {{ text("detecting") }}
      <LoadingDots loading />
    </p>
    <template
      v-else-if="
        state === ExtensionVerificationState.NOT_INSTALLED ||
        state === ExtensionVerificationState.OUTDATED
      "
    >
      <p
        class="extension-verification__description"
        :data-test="testId('install')"
      >
        {{
          state === ExtensionVerificationState.OUTDATED
            ? text("update")
            : text("install")
        }}
      </p>
      <SyncExtensionLinks compact />
    </template>
    <p v-else class="extension-verification__description">
      {{ text("description") }}
    </p>

    <Alert
      v-if="state === ExtensionVerificationState.MISMATCH"
      :variant="AlertVariantsEnum.DANGER"
      :size="AlertSizesEnum.COMPACT"
      :data-test="testId('mismatch')"
    >
      {{ text("handleMismatch") }}
    </Alert>
    <Alert
      v-else-if="state === ExtensionVerificationState.NOT_SIGNED_IN"
      :variant="AlertVariantsEnum.WARNING"
      :size="AlertSizesEnum.COMPACT"
      :data-test="testId('signed-out')"
    >
      {{ text("notSignedIn") }}
    </Alert>
    <div
      v-if="
        state === ExtensionVerificationState.MISMATCH ||
        state === ExtensionVerificationState.NOT_SIGNED_IN
      "
      class="extension-verification__session"
    >
      <Btn
        :href="RSI_SIGN_IN_URL"
        target="_blank"
        :size="BtnSizesEnum.SM"
        :data-test="testId('sign-in')"
      >
        <i class="icon icon-rsi" />
        {{ t("labels.syncExtension.signInToRsi") }}
        <i class="fa-light fa-arrow-up-right-from-square" />
      </Btn>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :data-test="testId('recheck')"
        @click="emit('redetect')"
      >
        <i class="fa-light fa-sync" />
        {{ t("labels.syncExtension.checkIdentity") }}
      </Btn>
    </div>

    <template v-else-if="state === ExtensionVerificationState.READY">
      <Alert
        v-if="error"
        :variant="AlertVariantsEnum.DANGER"
        :size="AlertSizesEnum.COMPACT"
        :data-test="testId('error')"
      >
        {{ text(error) }}
      </Alert>
      <div
        class="extension-verification__account"
        :data-test="testId('account')"
      >
        <RsiSignedInAs v-if="rsiHandle" :handle="rsiHandle" />
      </div>
      <Btn
        :size="BtnSizesEnum.SM"
        :loading="running || pending"
        :disabled="coolingDown && !pending"
        :data-test="testId('verify')"
        @click="emit('verify')"
      >
        <i class="fa-light fa-puzzle-piece" />
        {{ text("verify") }}
      </Btn>
      <Alert
        v-if="statusText && checkedByExtension"
        :variant="statusVariant"
        :icon="pending ? 'fa-duotone fa-spinner-third fa-spin' : undefined"
        :size="AlertSizesEnum.COMPACT"
        :data-test="testId('status')"
      >
        {{ statusText }}
      </Alert>
    </template>

    <div class="extension-verification__manual">
      {{ text("manual") }}
    </div>
  </div>
</template>

<style lang="scss" scoped>
.extension-verification {
  display: grid;
  gap: 8px;
  justify-items: start;
  margin-bottom: 20px;

  > :deep(.base-alert) {
    justify-self: stretch;
    margin-bottom: 0;
  }

  &__title {
    padding-top: 3px;
    font-weight: 600;
  }

  &__description {
    margin: 0;
    color: var(--color-text-dim);
  }

  &__session {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  &__account {
    font-weight: 600;
  }

  &__manual {
    justify-self: stretch;
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    color: var(--color-text-dim);
    font-size: 0.9em;
  }
}
</style>
