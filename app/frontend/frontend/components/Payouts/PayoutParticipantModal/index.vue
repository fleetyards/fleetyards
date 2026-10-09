<script lang="ts">
export default {
  name: "PayoutsPayoutParticipantModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import { useForm } from "vee-validate";
import { watchDebounced } from "@vueuse/core";
import { useI18n } from "@/shared/composables/useI18n";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  checkUsername,
  useCreatePayoutParticipant as useCreatePayoutParticipantMutation,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const initialValues = { username: "", name: "" };

const { defineField, handleSubmit, values } = useForm({
  initialValues,
});

// Read by AppModal, which asks before a close would throw typed input away.
defineExpose({ dirty: useFormDirty(values, initialValues) });

const [username, usernameProps] = defineField("username");
const [name, nameProps] = defineField("name");

const createMutation = useCreatePayoutParticipantMutation();

// Whether the username names a FleetYards account, answered as it is typed:
// otherwise a typo only surfaced as an error after saving, and nothing said
// that a name typed into the other field becomes an unlinked guest.
const accountFound = ref<boolean>();
const checkedUsername = ref<string>();

const normalize = (value: unknown) =>
  typeof value === "string" ? value.trim() : "";

watchDebounced(
  () => normalize(values.username),
  async (handle) => {
    accountFound.value = undefined;
    checkedUsername.value = undefined;

    if (!handle) return;

    const result = await checkUsername({ value: handle }).catch(
      () => undefined,
    );

    if (!result || normalize(values.username) !== handle) return;

    accountFound.value = result.taken;
    checkedUsername.value = handle;
  },
  { debounce: 300 },
);

const usernameUnknown = computed(
  () =>
    accountFound.value === false &&
    checkedUsername.value === normalize(values.username),
);

// Either a FleetYards account by username, or a plain name for someone who was
// on the tour but has no account. Sending both would be ambiguous, so the
// username wins and the name is dropped.
const onSubmit = handleSubmit(async (values) => {
  const handle = String(values.username ?? "").trim();
  const guestName = String(values.name ?? "").trim();

  if (!handle && !guestName) {
    displayAlert({ text: t("messages.payouts.participantNeedsName") });
    return;
  }

  if (handle && usernameUnknown.value) {
    return;
  }

  submitting.value = true;

  await createMutation
    .mutateAsync({
      payoutLedgerId: props.payoutLedgerId,
      data: handle ? { username: handle } : { name: guestName },
    })
    .then((participant) => {
      displaySuccess({
        text: participant.guest
          ? t("messages.payouts.participantAddedGuest", {
              name: participant.displayName,
            })
          : t("messages.payouts.participantAddedUser", {
              name: participant.displayName,
            }),
      });
      comlink.emit("payout-ledger-changed");
      comlink.emit("close-modal", true);
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal :title="t('headlines.payouts.addParticipant')">
    <form id="payout-participant-form" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12">
          <FormInput
            v-model="username"
            name="username"
            v-bind="usernameProps"
            :label="t('labels.payouts.username')"
            :autofocus="true"
            autocomplete="off"
          />
          <Alert
            v-if="accountFound && checkedUsername === username?.trim()"
            :variant="AlertVariantsEnum.SUCCESS"
            :size="AlertSizesEnum.COMPACT"
            data-test="payout-participant-account-found"
          >
            {{ t("texts.payouts.accountFound", { username: checkedUsername }) }}
          </Alert>
          <Alert
            v-else-if="usernameUnknown"
            :variant="AlertVariantsEnum.WARNING"
            :size="AlertSizesEnum.COMPACT"
            data-test="payout-participant-account-missing"
          >
            {{ t("texts.payouts.accountMissing") }}
          </Alert>
        </div>
        <div class="col-12">
          <p class="payout-participant-modal__or">{{ t("labels.or") }}</p>
        </div>
        <div class="col-12">
          <FormInput
            v-model="name"
            name="name"
            v-bind="nameProps"
            :label="t('labels.payouts.name')"
            :disabled="!!username?.trim()"
          />
          <p class="payout-participant-modal__hint">
            {{ t("texts.payouts.guestHint") }}
          </p>
        </div>
      </div>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="payout-participant-form"
        :loading="submitting"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.payout-participant-modal__hint {
  margin: -8px 0 0;
  font-size: 12px;
  color: var(--color-text-dim, #959595);
}

.payout-participant-modal__or {
  margin: 0;
  text-align: center;
  text-transform: uppercase;
  font-size: 11px;
  letter-spacing: 0.04em;
  color: var(--color-muted, #7a8288);
}
</style>
