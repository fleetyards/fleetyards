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
import {
  FleetyardsSyncAction,
  type FleetyardsSyncVerifyPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";
import {
  ExtensionVerificationState,
  accountIsTarget,
  useExtensionVerification,
} from "@/frontend/composables/useExtensionVerification";
import ExtensionVerificationBlock from "@/frontend/components/ExtensionVerificationBlock/index.vue";

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

const extension = useExtensionVerification({
  target: () =>
    verification.value?.verified === false ? verification.value.handle : null,
  token: () => verification.value?.token,
  writeAction: FleetyardsSyncAction.VERIFY_WRITE,
  removeAction: FleetyardsSyncAction.VERIFY_REMOVE,
  params: (token) => ({ token }),
  accountMatches: accountIsTarget,
  wroteToTarget: (answer, handle) =>
    accountIsTarget(
      (answer.payload as FleetyardsSyncVerifyPayload)?.handle ?? "",
      handle,
    ),
  check,
  checkStatus: () => verification.value?.status,
  pendingStatus: StatusEnum.PENDING,
  errors: { 413: "bioTooLong", 422: "bioUnreadable" },
  onRemoveFailed: () =>
    displayAlert({
      text: t("labels.user.rsiVerification.extension.removeFailed"),
    }),
});

const checkManually = () => {
  extension.forgetCheck();
  void check();
};

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

      <ExtensionVerificationBlock
        v-if="extension.state.value !== ExtensionVerificationState.NONE"
        scope="user"
        test-prefix="user-rsi-verification"
        :state="extension.state.value"
        :target="verification.handle"
        :rsi-handle="extension.rsiHandle.value"
        :error="extension.error.value"
        :running="extension.running.value"
        :checked-by-extension="extension.checkedByExtension.value"
        :status-text="statusText"
        :status-variant="statusVariant"
        :pending="pending"
        :cooling-down="coolingDown"
        @verify="extension.verify"
        @redetect="extension.redetect"
      />

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
            v-if="statusText && !extension.checkedByExtension.value"
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
          @click="checkManually"
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
</style>
