<script lang="ts">
export default {
  name: "PayoutsPayoutParticipantModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useCreatePayoutParticipant as useCreatePayoutParticipantMutation } from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const { defineField, handleSubmit } = useForm({
  initialValues: { username: "", name: "" },
});

const [username, usernameProps] = defineField("username");
const [name, nameProps] = defineField("name");

const createMutation = useCreatePayoutParticipantMutation();

// Either a FleetYards account by username, or a plain name for someone who was
// on the tour but has no account. Sending both would be ambiguous, so the
// username wins and the name is dropped.
const onSubmit = handleSubmit(async (values) => {
  const handle = String(values.username ?? "").trim();
  const guestName = String(values.name ?? "").trim();

  if (!handle && !guestName) {
    displayAlert({ text: t("labels.payouts.username") });
    return;
  }

  submitting.value = true;

  await createMutation
    .mutateAsync({
      payoutLedgerId: props.payoutLedgerId,
      data: handle ? { username: handle } : { name: guestName },
    })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.participantAdded") });
      comlink.emit("payout-ledger-changed");
      comlink.emit("close-modal");
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
          />
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
          />
        </div>
      </div>
    </form>

    <template #footer>
      <div class="modal-actions">
        <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.payout-participant-modal__or {
  margin: 0;
  text-align: center;
  text-transform: uppercase;
  font-size: 11px;
  letter-spacing: 0.04em;
  color: var(--color-muted, #999);
}
</style>
