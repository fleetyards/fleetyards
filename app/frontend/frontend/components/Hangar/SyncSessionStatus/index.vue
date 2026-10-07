<script lang="ts">
export default {
  name: "HangarSyncSessionStatus",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import LoadingDots from "@/shared/components/LoadingDots/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { RSI_SIGN_IN_URL } from "@/frontend/lib/rsiLinks";
import RsiSignedInAs from "@/frontend/components/RsiSignedInAs/index.vue";

export type SyncIdentityStatus = "pending" | "connected" | "notFound";

type Props = {
  status: SyncIdentityStatus;
  loading?: boolean;
  handle?: string;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  handle: undefined,
});

const emit = defineEmits<{ recheck: [] }>();

const { t } = useI18n();

const STATUS_CLASSES: Record<SyncIdentityStatus, string> = {
  pending: "text-warning",
  connected: "text-success",
  notFound: "text-danger",
};
</script>

<template>
  <div class="sync-session-status" data-test="sync-session-status">
    <p class="sync-session-status__line" :class="STATUS_CLASSES[props.status]">
      <span class="sync-session-status__text">
        {{ t("labels.syncExtension.sessionStatus") }}:
        {{ t(`labels.syncExtension.identityStatus.${props.status}`) }}
        <span class="sync-session-status__trail">
          <LoadingDots :loading="loading" />
          <Btn
            v-if="props.status === 'notFound'"
            v-tooltip="t('labels.syncExtension.checkIdentity')"
            :aria-label="t('labels.syncExtension.checkIdentity')"
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :disabled="loading"
            data-test="sync-session-recheck"
            @click="emit('recheck')"
          >
            <i class="fa-light fa-sync" />
          </Btn>
        </span>
      </span>
    </p>
    <p
      v-if="props.status === 'connected' && handle"
      class="sync-session-status__account"
      data-test="sync-extension-signed-in-as"
    >
      <RsiSignedInAs :handle="handle" />
    </p>
    <p
      v-else-if="props.status === 'notFound'"
      class="sync-session-status__account"
    >
      <a
        :href="RSI_SIGN_IN_URL"
        target="_blank"
        rel="noopener"
        class="sync-session-status__link"
        data-test="sync-session-sign-in"
      >
        {{ t("labels.syncExtension.signInToRsi") }}
        <i class="fa-light fa-arrow-up-right-from-square" />
      </a>
    </p>
  </div>
</template>

<style lang="scss" scoped>
.sync-session-status {
  margin-top: 16px;
  text-align: center;

  &__line {
    margin: 0 0 8px;
    text-transform: uppercase;
  }

  // The text alone is what sits centred; the dots and the retry button hang
  // off its end, so they never push it to one side.
  &__text {
    position: relative;
  }

  &__trail {
    position: absolute;
    top: 50%;
    left: 100%;
    display: flex;
    align-items: center;
    padding-left: 6px;
    transform: translateY(-50%);
    white-space: nowrap;
  }

  &__account {
    margin: 0 0 16px;
  }

  &__link {
    display: block;
    font-size: 0.9em;
  }
}
</style>
