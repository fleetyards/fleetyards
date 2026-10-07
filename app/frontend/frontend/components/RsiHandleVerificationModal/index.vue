<script lang="ts">
export default {
  name: "RsiHandleVerificationModal",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import { useIntervalFn, useNow } from "@vueuse/core";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import copyText from "@/frontend/utils/CopyText";
import {
  type UserRsiVerification,
  NullableRsiHandleVerifiedViaEnum as VerifiedViaEnum,
  NullableUserRsiVerificationStatusEnum as StatusEnum,
  getMyRsiVerificationQueryKey,
  useCheckMyRsiVerification,
  useCreateMyRsiVerification,
  useMyRsiVerification,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncSessionPayload,
  type FleetyardsSyncVerifyPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";

const RSI_PROFILE_SETTINGS_URL =
  "https://robertsspaceindustries.com/account/settings/profile";

const { t, l } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const queryClient = useQueryClient();

const comlink = useComlink();

const root = ref<HTMLElement>();

// A check is a job, so the answer arrives a second or two after the request.
const POLL_INTERVAL = 2000;

// A check still pending once the cooldown is over was lost on the way (a
// deploy, a dropped job); the reader can start another rather than wait.
const awaitingCheck = (data?: UserRsiVerification) =>
  data?.status === StatusEnum.PENDING &&
  !!data.nextCheckAt &&
  new Date(data.nextCheckAt).getTime() > Date.now();

const { data: verification } = useMyRsiVerification({
  query: {
    refetchInterval: (query) =>
      awaitingCheck(query.state.data) ? POLL_INTERVAL : false,
  },
});

const createMutation = useCreateMyRsiVerification();

const checkMutation = useCheckMyRsiVerification();

const now = useNow({ scheduler: (tick) => useIntervalFn(tick, 1000) });

const coolingDown = computed(() => {
  const nextCheckAt = verification.value?.nextCheckAt;

  return !!nextCheckAt && new Date(nextCheckAt) > now.value;
});

// Counted down on the button, so a disabled Check says when it comes back
// instead of looking broken.
const secondsUntilNextCheck = computed(() => {
  const nextCheckAt = verification.value?.nextCheckAt;
  if (!nextCheckAt) return 0;

  return Math.max(
    0,
    Math.ceil((new Date(nextCheckAt).getTime() - now.value.getTime()) / 1000),
  );
});

const pending = computed(
  () => verification.value?.status === StatusEnum.PENDING && coolingDown.value,
);

// Once verified, the token may have been taken out of the bio again, so what a
// later check found there says nothing about the verification.
const statusText = computed(() => {
  const status = verification.value?.status;
  if (!status || verification.value?.verified) return undefined;
  if (status === StatusEnum.PENDING && !pending.value) return undefined;

  return t(`labels.user.rsiVerification.statuses.${status}`);
});

const STATUS_VARIANTS: Partial<Record<string, `${AlertVariantsEnum}`>> = {
  [StatusEnum.PENDING]: AlertVariantsEnum.INFO,
  [StatusEnum.TOKEN_MISSING]: AlertVariantsEnum.WARNING,
  [StatusEnum.HANDLE_MISMATCH]: AlertVariantsEnum.DANGER,
  [StatusEnum.NOT_FOUND]: AlertVariantsEnum.DANGER,
  [StatusEnum.FAILED]: AlertVariantsEnum.DANGER,
};

const statusVariant = computed(
  () =>
    STATUS_VARIANTS[verification.value?.status ?? ""] ??
    AlertVariantsEnum.NEUTRAL,
);

const verifiedTitle = computed(() =>
  verification.value?.verifiedVia === VerifiedViaEnum.CITIZENID
    ? t("labels.user.rsiHandleVerified")
    : t("labels.user.rsiHandleVerifiedViaProfile"),
);

const close = () => {
  comlink.emit("close-modal");
};

const refresh = (data: unknown) => {
  queryClient.setQueryData(getMyRsiVerificationQueryKey(), data);
};

const generateToken = async () => {
  try {
    refresh(await createMutation.mutateAsync());
  } catch (error) {
    displayAlert({ text: validationErrorFrom(error).message });
  }
};

const check = async () => {
  try {
    refresh(await checkMutation.mutateAsync());
  } catch (error) {
    displayAlert({ text: validationErrorFrom(error).message });
  }
};

watch(
  () => verification.value?.verified,
  (verified, wasVerified) => {
    if (verified === wasVerified || wasVerified === undefined) return;

    // The profile behind the modal reads the session's copy of the user.
    comlink.emit("user-update");
  },
);

const extension = useSyncExtension();

type ExtensionState = "unavailable" | "notSignedIn" | "mismatch" | "ready";

const extensionState = ref<ExtensionState>("unavailable");

const extensionHandle = ref<string>();

const extensionError = ref<"bioTooLong" | "bioUnreadable" | "failed">();

const extensionRunning = ref(false);

// The token the extension added to the bio, until it has taken it out again.
const tokenInBio = ref<string>();

const detectExtension = async (handle: string) => {
  if (!(await extension.supports(FleetyardsSyncAction.VERIFY_WRITE))) return;

  const identity = await extension
    .request(FleetyardsSyncAction.IDENTIFY)
    .catch(() => undefined);
  const rsiHandle = (identity?.payload as FleetyardsSyncSessionPayload)?.handle;

  if (identity?.code !== 200 || !rsiHandle) {
    extensionState.value = "notSignedIn";
  } else {
    extensionHandle.value = rsiHandle;
    extensionState.value =
      rsiHandle.toLowerCase() === handle.toLowerCase() ? "ready" : "mismatch";
  }
};

watch(
  () =>
    verification.value?.verified === false
      ? verification.value.handle
      : undefined,
  (handle) => {
    extensionState.value = "unavailable";
    if (handle) void detectExtension(handle);
  },
  { immediate: true },
);

const EXTENSION_ERRORS: Record<number, "bioTooLong" | "bioUnreadable"> = {
  413: "bioTooLong",
  422: "bioUnreadable",
};

const removeTokenFromBio = () => {
  const token = tokenInBio.value;
  if (!token) return;

  tokenInBio.value = undefined;
  extension
    .request(FleetyardsSyncAction.VERIFY_REMOVE, { token })
    .catch(() => undefined);
};

const verifyWithExtension = async () => {
  const token = verification.value?.token;
  if (!token) return;

  extensionError.value = undefined;
  extensionRunning.value = true;

  try {
    const result = await extension
      .request(FleetyardsSyncAction.VERIFY_WRITE, { token })
      .catch(() => undefined);

    if (result?.code !== 200) {
      extensionError.value = EXTENSION_ERRORS[result?.code ?? 0] ?? "failed";
      return;
    }

    await check();

    if ((result.payload as FleetyardsSyncVerifyPayload)?.changed) {
      tokenInBio.value = token;
    }
  } finally {
    extensionRunning.value = false;
  }
};

// The check reads the bio once and is done with it, so the token comes out as
// soon as there is an answer. Closing the modal takes it out regardless.
watch([tokenInBio, pending], () => {
  if (tokenInBio.value && !pending.value) removeTokenFromBio();
});

onBeforeUnmount(removeTokenFromBio);

const copyToken = () => {
  const token = verification.value?.token;
  if (!token) return;

  // Inside the modal: a copy staged outside a focus trap copies nothing while
  // still reporting success.
  copyText(token, root.value ?? undefined).then(
    () => displaySuccess({ text: t("messages.copy.success") }),
    () => displayAlert({ text: t("messages.copy.failure") }),
  );
};
</script>

<template>
  <Modal :title="t('labels.user.rsiVerification.title')">
    <section
      v-if="verification"
      ref="root"
      class="rsi-verification"
      data-test="user-rsi-verification"
    >
      <Alert
        v-if="verification.verified"
        :variant="AlertVariantsEnum.SUCCESS"
        :title="verifiedTitle"
        data-test="user-rsi-verified"
      >
        <template v-if="verification.verifiedAt">
          {{
            t("labels.user.rsiVerification.verifiedSince", {
              date: l(verification.verifiedAt),
            })
          }}
        </template>
      </Alert>

      <div
        v-if="!verification.verified && extensionState !== 'unavailable'"
        class="rsi-verification__extension"
        data-test="user-rsi-verification-extension"
      >
        <div class="rsi-verification__step-title">
          {{ t("labels.user.rsiVerification.extension.title") }}
        </div>
        <p class="rsi-verification__extension-description">
          {{ t("labels.user.rsiVerification.extension.description") }}
        </p>
        <Alert
          v-if="extensionState === 'mismatch'"
          :variant="AlertVariantsEnum.DANGER"
          :size="AlertSizesEnum.COMPACT"
          data-test="user-rsi-verification-extension-mismatch"
        >
          {{
            t("labels.user.rsiVerification.extension.handleMismatch", {
              rsiHandle: extensionHandle,
              handle: verification.handle,
            })
          }}
        </Alert>
        <Alert
          v-else-if="extensionState === 'notSignedIn'"
          :variant="AlertVariantsEnum.WARNING"
          :size="AlertSizesEnum.COMPACT"
          data-test="user-rsi-verification-extension-signed-out"
        >
          {{ t("labels.user.rsiVerification.extension.notSignedIn") }}
        </Alert>
        <template v-else>
          <Alert
            v-if="extensionError"
            :variant="AlertVariantsEnum.DANGER"
            :size="AlertSizesEnum.COMPACT"
            data-test="user-rsi-verification-extension-error"
          >
            {{ t(`labels.user.rsiVerification.extension.${extensionError}`) }}
          </Alert>
          <Btn
            :size="BtnSizesEnum.SM"
            :loading="extensionRunning || pending"
            :disabled="coolingDown && !pending"
            data-test="user-rsi-verification-extension-verify"
            @click="verifyWithExtension"
          >
            <i class="fa-light fa-puzzle-piece" />
            {{ t("actions.user.rsiVerification.verifyWithExtension") }}
          </Btn>
        </template>
        <div class="rsi-verification__extension-manual">
          {{ t("labels.user.rsiVerification.extension.manual") }}
        </div>
      </div>

      <ol v-if="!verification.verified" class="rsi-verification__steps">
        <li class="rsi-verification__step">
          <div class="rsi-verification__step-title">
            {{ t("labels.user.rsiVerification.steps.copy") }}
          </div>
          <template v-if="verification.token">
            <FormInput
              name="rsiVerificationToken"
              :model-value="verification.token"
              :label="t('labels.user.rsiVerification.token')"
              no-label
              data-test="user-rsi-verification-token"
            >
              <template #suffix>
                <button
                  type="button"
                  class="rsi-verification__copy"
                  :aria-label="t('actions.user.rsiVerification.copyToken')"
                  :title="t('actions.user.rsiVerification.copyToken')"
                  data-test="user-rsi-verification-copy"
                  @click="copyToken"
                >
                  <i class="fa-light fa-copy" />
                </button>
              </template>
            </FormInput>
            <Btn
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.BARE"
              :loading="createMutation.isPending.value"
              data-test="user-rsi-verification-generate"
              @click="generateToken"
            >
              {{ t("actions.user.rsiVerification.regenerateToken") }}
            </Btn>
          </template>
        </li>

        <li class="rsi-verification__step">
          <div class="rsi-verification__step-title">
            {{ t("labels.user.rsiVerification.steps.paste") }}
          </div>
          <Btn
            :href="RSI_PROFILE_SETTINGS_URL"
            target="_blank"
            :size="BtnSizesEnum.SM"
          >
            <i class="icon icon-rsi" />
            {{ t("labels.user.rsiVerification.openProfileSettings") }}
            <i class="fa-light fa-arrow-up-right-from-square" />
          </Btn>
        </li>

        <li class="rsi-verification__step">
          <div class="rsi-verification__step-title">
            {{
              t("labels.user.rsiVerification.steps.check", {
                handle: verification.handle,
              })
            }}
          </div>
          <Alert
            v-if="statusText"
            :variant="statusVariant"
            :icon="pending ? 'fa-duotone fa-spinner-third fa-spin' : undefined"
            :size="AlertSizesEnum.COMPACT"
            data-test="user-rsi-verification-status"
          >
            {{ statusText }}
          </Alert>
        </li>
      </ol>
    </section>

    <template #footer>
      <div class="modal-actions">
        <Btn :variant="BtnVariantsEnum.GHOST" @click="close">
          {{ t("actions.close") }}
        </Btn>
        <Btn
          v-if="
            verification?.handle && verification.token && !verification.verified
          "
          :loading="checkMutation.isPending.value || pending"
          :disabled="coolingDown && !pending"
          data-test="user-rsi-verification-check"
          @click="check"
        >
          <template v-if="coolingDown && !pending">
            {{
              t("actions.user.rsiVerification.checkIn", {
                seconds: secondsUntilNextCheck,
              })
            }}
          </template>
          <template v-else>
            {{ t("actions.user.rsiVerification.check") }}
          </template>
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/rsiVerification";

.rsi-verification {
  &__extension {
    display: grid;
    gap: 8px;
    justify-items: start;
    margin-bottom: 20px;

    > :deep(.base-alert) {
      justify-self: stretch;
      margin-bottom: 0;
    }
  }

  &__extension-description {
    margin: 0;
    color: var(--color-text-dim);
  }

  &__extension-manual {
    justify-self: stretch;
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    color: var(--color-text-dim);
    font-size: 0.9em;
  }
}
</style>
