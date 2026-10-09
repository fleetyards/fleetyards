<script lang="ts">
export default {
  name: "FleetRsiVerificationModal",
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
  type Fleet,
  type FleetRsiVerification,
  NullableFleetRsiVerificationStatusEnum as StatusEnum,
  getFleetRsiVerificationQueryKey,
  useCheckFleetRsiVerification,
  useCreateFleetRsiVerification,
  useFleetRsiVerification,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";
import {
  ExtensionVerificationState,
  useExtensionVerification,
} from "@/frontend/composables/useExtensionVerification";
import ExtensionVerificationBlock from "@/frontend/components/ExtensionVerificationBlock/index.vue";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const queryClient = useQueryClient();

const comlink = useComlink();

const root = ref<HTMLElement>();

// A check is a job, so the answer arrives a second or two after the request.
const POLL_INTERVAL = 2000;

// A check still pending once the cooldown is over was lost on the way (a
// deploy, a dropped job); the reader can start another rather than wait.
const awaitingCheck = (data?: FleetRsiVerification) =>
  data?.status === StatusEnum.PENDING &&
  !!data.nextCheckAt &&
  new Date(data.nextCheckAt).getTime() > Date.now();

const { data: verification } = useFleetRsiVerification(() => props.fleet.slug, {
  query: {
    refetchInterval: (query) =>
      awaitingCheck(query.state.data) ? POLL_INTERVAL : false,
  },
});

const createMutation = useCreateFleetRsiVerification();

const checkMutation = useCheckFleetRsiVerification();

const orgPageUrl = computed(() =>
  verification.value?.sid
    ? `https://robertsspaceindustries.com/orgs/${verification.value.sid}`
    : undefined,
);

const now = useNow({ scheduler: (tick) => useIntervalFn(tick, 1000) });

const coolingDown = computed(() => {
  const nextCheckAt = verification.value?.nextCheckAt;

  return !!nextCheckAt && new Date(nextCheckAt) > now.value;
});

const pending = computed(
  () => verification.value?.status === StatusEnum.PENDING && coolingDown.value,
);

// Once verified, the token may have been taken off the page again, so what a
// later check found there says nothing about the verification.
const statusText = computed(() => {
  const status = verification.value?.status;
  if (!status || verification.value?.verified) return undefined;
  if (status === StatusEnum.PENDING && !pending.value) return undefined;

  return t(`labels.fleet.rsiVerification.statuses.${status}`);
});

// The answer a check can give, read as the notice it deserves: still looking,
// something the manager can fix on the page, or a failure on RSI's side.
const STATUS_VARIANTS: Partial<Record<string, `${AlertVariantsEnum}`>> = {
  [StatusEnum.PENDING]: AlertVariantsEnum.INFO,
  [StatusEnum.TOKEN_MISSING]: AlertVariantsEnum.WARNING,
  [StatusEnum.SYMBOL_MISMATCH]: AlertVariantsEnum.DANGER,
  [StatusEnum.NOT_FOUND]: AlertVariantsEnum.DANGER,
  [StatusEnum.FAILED]: AlertVariantsEnum.DANGER,
};

const statusVariant = computed(
  () =>
    STATUS_VARIANTS[verification.value?.status ?? ""] ??
    AlertVariantsEnum.NEUTRAL,
);

const close = () => {
  comlink.emit("close-modal");
};

const refresh = (data: unknown) => {
  queryClient.setQueryData(
    getFleetRsiVerificationQueryKey(props.fleet.slug),
    data,
  );
};

const generateToken = async () => {
  try {
    refresh(await createMutation.mutateAsync({ fleetSlug: props.fleet.slug }));
  } catch (error) {
    displayAlert({ text: validationErrorFrom(error).message });
  }
};

const check = async () => {
  try {
    refresh(await checkMutation.mutateAsync({ fleetSlug: props.fleet.slug }));
  } catch (error) {
    displayAlert({ text: validationErrorFrom(error).message });
  }
};

watch(
  () => verification.value?.verified,
  (verified, wasVerified) => {
    if (verified === wasVerified || wasVerified === undefined) return;

    // The page behind the modal shows the fleet's own copy of the answer.
    comlink.emit("fleet-update");
  },
);

const extension = useExtensionVerification({
  target: () =>
    verification.value?.verified === false ? verification.value.sid : null,
  token: () => verification.value?.token,
  writeAction: FleetyardsSyncAction.ORG_VERIFY_WRITE,
  removeAction: FleetyardsSyncAction.ORG_VERIFY_REMOVE,
  params: (token) => ({ sid: verification.value?.sid, token }),
  check,
  checkStatus: () => verification.value?.status,
  pendingStatus: StatusEnum.PENDING,
  errors: { 403: "noRights", 409: "pendingChanges", 422: "orgUnreadable" },
  onRemoveFailed: (params) =>
    displayAlert({
      text: t("labels.fleet.rsiVerification.extension.removeFailed", {
        sid: params.sid,
      }),
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
  <Modal :title="t('labels.fleet.rsiVerification.title')">
    <section
      v-if="verification"
      ref="root"
      class="rsi-verification"
      data-test="fleet-rsi-verification"
    >
      <Alert
        v-if="verification.verified"
        :variant="AlertVariantsEnum.SUCCESS"
        :title="t('labels.fleet.rsiVerification.verified')"
        data-test="fleet-rsi-verified"
      >
        <template v-if="verification.verifiedAt">
          {{
            t("labels.fleet.rsiVerification.verifiedSince", {
              date: l(verification.verifiedAt),
            })
          }}
        </template>
      </Alert>

      <ExtensionVerificationBlock
        v-if="extension.state.value !== ExtensionVerificationState.NONE"
        scope="fleet"
        test-prefix="fleet-rsi-verification"
        :state="extension.state.value"
        :target="verification.sid"
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
            {{ t("labels.fleet.rsiVerification.steps.copy") }}
          </div>
          <template v-if="verification.token">
            <FormInput
              name="rsiVerificationToken"
              :model-value="verification.token"
              :label="t('labels.fleet.rsiVerification.token')"
              no-label
              data-test="fleet-rsi-verification-token"
            >
              <template #suffix>
                <button
                  type="button"
                  class="rsi-verification__copy"
                  :aria-label="t('actions.fleet.rsiVerification.copyToken')"
                  :title="t('actions.fleet.rsiVerification.copyToken')"
                  data-test="fleet-rsi-verification-copy"
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
              data-test="fleet-rsi-verification-generate"
              @click="generateToken"
            >
              {{ t("actions.fleet.rsiVerification.regenerateToken") }}
            </Btn>
          </template>
        </li>

        <li class="rsi-verification__step">
          <div class="rsi-verification__step-title">
            {{ t("labels.fleet.rsiVerification.steps.paste") }}
          </div>
          <Btn
            v-if="orgPageUrl"
            :href="orgPageUrl"
            target="_blank"
            :size="BtnSizesEnum.SM"
          >
            <i class="icon icon-rsi" />
            {{
              t("labels.fleet.rsiVerification.openOrgPage", {
                sid: verification.sid,
              })
            }}
            <i class="fa-light fa-arrow-up-right-from-square" />
          </Btn>
        </li>

        <li class="rsi-verification__step">
          <div class="rsi-verification__step-title">
            {{ t("labels.fleet.rsiVerification.steps.check") }}
          </div>
          <Alert
            v-if="statusText && !extension.checkedByExtension.value"
            :variant="statusVariant"
            :icon="pending ? 'fa-duotone fa-spinner-third fa-spin' : undefined"
            :size="AlertSizesEnum.COMPACT"
            data-test="fleet-rsi-verification-status"
          >
            {{ statusText }}
          </Alert>
          <p v-else-if="coolingDown" class="text-muted small">
            {{ t("labels.fleet.rsiVerification.nextCheck") }}
          </p>
        </li>
      </ol>
    </section>

    <template #footer>
      <Btn
        :size="BtnSizesEnum.LG"
        :variant="BtnVariantsEnum.BARE"
        @click="close"
      >
        {{ t("actions.close") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.LG"
        v-if="verification?.sid && verification.token && !verification.verified"
        :loading="checkMutation.isPending.value || pending"
        :disabled="coolingDown && !pending"
        data-test="fleet-rsi-verification-check"
        @click="checkManually"
      >
        {{ t("actions.fleet.rsiVerification.check") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/rsiVerification";
</style>
