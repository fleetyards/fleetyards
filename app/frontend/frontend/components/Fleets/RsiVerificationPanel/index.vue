<script lang="ts">
export default {
  name: "FleetRsiVerificationPanel",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import { useIntervalFn, useNow } from "@vueuse/core";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import copyText from "@/frontend/utils/CopyText";
import {
  type Fleet,
  type FleetRsiVerification,
  NullableFleetRsiVerificationStatusEnum as StatusEnum,
  getFleetQueryKey,
  getFleetRsiVerificationQueryKey,
  useCheckFleetRsiVerification,
  useCreateFleetRsiVerification,
  useFleetRsiVerification,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { fidAtRisk } from "@/frontend/utils/rsiSid";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const queryClient = useQueryClient();

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

const showFidWarning = computed(() => fidAtRisk(props.fleet));

const refresh = (data: unknown) => {
  queryClient.setQueryData(
    getFleetRsiVerificationQueryKey(props.fleet.slug),
    data,
  );
};

const generateToken = async () => {
  refresh(await createMutation.mutateAsync({ fleetSlug: props.fleet.slug }));
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

    void queryClient.invalidateQueries({
      queryKey: getFleetQueryKey(props.fleet.slug),
    });
  },
);

// A saved SID resets the verification on the server.
watch(
  () => props.fleet.rsiSid,
  () => {
    void queryClient.invalidateQueries({
      queryKey: getFleetRsiVerificationQueryKey(props.fleet.slug),
    });
  },
);

const copyToken = () => {
  const token = verification.value?.token;
  if (!token) return;

  copyText(token).then(
    () => displaySuccess({ text: t("messages.copy.success") }),
    () => displayAlert({ text: t("messages.copy.failure") }),
  );
};
</script>

<template>
  <section class="rsi-verification" data-test="fleet-rsi-verification">
    <Heading :level="HeadingLevelEnum.H2" mt>
      {{ t("labels.fleet.rsiVerification.title") }}
    </Heading>

    <Panel
      v-if="showFidWarning"
      class="rsi-verification__warning"
      inset
      data-test="fleet-fid-at-risk"
    >
      <p>
        {{ t("labels.fleet.rsiVerification.fidAtRisk", { fid: fleet.fid }) }}
      </p>
    </Panel>

    <p class="text-muted">
      {{ t("labels.fleet.rsiVerification.hint") }}
    </p>

    <p v-if="!verification?.sid">
      {{ t("labels.fleet.rsiVerification.noSid") }}
    </p>

    <template v-else>
      <p class="rsi-verification__status">
        <Pill
          v-if="verification.verified"
          :variant="PillVariantsEnum.SUCCESS"
          data-test="fleet-rsi-verified"
        >
          <i class="fa-duotone fa-badge-check" />
          {{ t("labels.fleet.rsiVerification.verified") }}
        </Pill>
        <Pill v-else :variant="PillVariantsEnum.NEUTRAL">
          {{ t("labels.fleet.rsiVerification.unverified") }}
        </Pill>
        <span v-if="verification.verifiedAt" class="text-muted small">
          {{
            t("labels.fleet.rsiVerification.verifiedSince", {
              date: l(verification.verifiedAt),
            })
          }}
        </span>
      </p>

      <p v-if="statusText" data-test="fleet-rsi-verification-status">
        <i v-if="pending" class="fa-light fa-spinner fa-spin" />
        {{ statusText }}
      </p>

      <div v-if="verification.token" class="rsi-verification__token">
        <span class="text-muted small">
          {{ t("labels.fleet.rsiVerification.token") }}
        </span>
        <code data-test="fleet-rsi-verification-token">
          {{ verification.token }}
        </code>
        <Btn :size="BtnSizesEnum.SM" variant="bare" @click="copyToken">
          <i class="fa-light fa-copy" />
          {{ t("actions.fleet.rsiVerification.copyToken") }}
        </Btn>
      </div>

      <p v-if="orgPageUrl">
        <a :href="orgPageUrl" target="_blank" rel="noopener">
          <i class="icon icon-rsi" />
          {{ t("labels.fleet.rsiVerification.openOrgPage") }}
        </a>
      </p>

      <div class="rsi-verification__actions">
        <Btn
          :size="BtnSizesEnum.SM"
          :loading="createMutation.isPending.value"
          data-test="fleet-rsi-verification-generate"
          @click="generateToken"
        >
          {{
            verification.token
              ? t("actions.fleet.rsiVerification.regenerateToken")
              : t("actions.fleet.rsiVerification.generateToken")
          }}
        </Btn>
        <Btn
          v-if="verification.token && !verification.verified"
          :size="BtnSizesEnum.SM"
          :loading="checkMutation.isPending.value || pending"
          :disabled="coolingDown && !pending"
          data-test="fleet-rsi-verification-check"
          @click="check"
        >
          {{ t("actions.fleet.rsiVerification.check") }}
        </Btn>
        <span
          v-if="coolingDown && !pending && !verification.verified"
          class="text-muted small"
        >
          {{ t("labels.fleet.rsiVerification.nextCheck") }}
        </span>
      </div>
    </template>
  </section>
</template>

<style lang="scss" scoped>
.rsi-verification {
  &__status {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
  }

  &__token {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
    margin-bottom: 1rem;

    code {
      user-select: all;
      word-break: break-all;
    }
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
  }

  &__warning {
    margin-bottom: 1rem;
  }
}
</style>
