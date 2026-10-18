<script lang="ts">
export default {
  name: "HangarSyncSessionStatus",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { RSI_SIGN_IN_URL } from "@/frontend/lib/rsiLinks";
import RsiSignedInAs from "@/frontend/components/RsiSignedInAs/index.vue";

export type SyncIdentityStatus = "pending" | "connected" | "notFound";

type Props = {
  status: SyncIdentityStatus;
  loading?: boolean;
  handle?: string;
  // What the sync does with the session, under the account it is signed in as.
  hint?: string;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  handle: undefined,
  hint: undefined,
});

const emit = defineEmits<{ recheck: [] }>();

const { t } = useI18n();
</script>

<template>
  <div class="sync-session-status" data-test="sync-session-status">
    <Alert
      v-if="props.status === 'notFound'"
      :variant="AlertVariantsEnum.WARNING"
      :size="AlertSizesEnum.COMPACT"
      :title="t('texts.syncExtension.signedOutTitle')"
    >
      {{ t("texts.syncExtension.signedOut") }}
      <template #actions>
        <Btn
          :href="RSI_SIGN_IN_URL"
          target="_blank"
          :variant="BtnVariantsEnum.GHOST"
          data-test="sync-session-sign-in"
        >
          {{ t("labels.syncExtension.signInToRsi") }}
          <i class="fa-light fa-arrow-up-right-from-square" />
        </Btn>
        <Btn
          :variant="BtnVariantsEnum.BARE"
          :loading="loading"
          data-test="sync-session-recheck"
          @click="emit('recheck')"
        >
          {{ t("actions.syncExtension.checkAgain") }}
        </Btn>
      </template>
    </Alert>

    <div
      v-else
      class="sync-session-status__row"
      :class="`sync-session-status__row--${props.status}`"
    >
      <span class="sync-session-status__dot" aria-hidden="true" />
      <span class="sync-session-status__text">
        <span
          v-if="props.status === 'connected' && handle"
          class="sync-session-status__account"
          data-test="sync-extension-signed-in-as"
        >
          <RsiSignedInAs :handle="handle" />
        </span>
        <span v-else class="sync-session-status__account">
          {{ t(`labels.syncExtension.identityStatus.${props.status}`) }}
        </span>
        <span
          v-if="props.status === 'connected' && hint"
          class="sync-session-status__hint"
        >
          {{ hint }}
        </span>
      </span>
      <Btn
        v-tooltip="t('labels.syncExtension.checkIdentity')"
        :aria-label="t('labels.syncExtension.checkIdentity')"
        :variant="BtnVariantsEnum.BARE"
        :loading="loading"
        data-test="sync-session-recheck"
        @click="emit('recheck')"
      >
        <i class="fa-light fa-arrows-rotate" />
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// Quiet while all is well: the session is a precondition, not news. Only a
// missing session raises a notice.
.sync-session-status__row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 8px 10px 14px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
}

.sync-session-status__dot {
  flex-shrink: 0;
  width: 10px;
  height: 10px;
  border-radius: 999px;
  background-color: var(--color-muted, #7a8288);
}

.sync-session-status__row--connected .sync-session-status__dot {
  background-color: var(--color-success, #5cb85c);
}

.sync-session-status__text {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.sync-session-status__account {
  color: var(--color-lifted, #eee);
  font-size: 15px;
}

.sync-session-status__hint {
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}
</style>
