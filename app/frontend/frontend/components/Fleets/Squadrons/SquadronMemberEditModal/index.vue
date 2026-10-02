<script lang="ts">
export default {
  name: "SquadronMemberDateModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type FleetSquadronMemberUpdateInput,
  useUpdateFleetSquadronMember,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  squadronSlug: string;
  username: string;
  membershipCreatedAt: string;
};

const props = defineProps<Props>();
const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const submitting = ref(false);

const { defineField, handleSubmit, setErrors } =
  useForm<FleetSquadronMemberUpdateInput>({
    initialValues: {
      createdAt: props.membershipCreatedAt.slice(0, 10),
    },
  });

const [createdAt, createdAtProps] = defineField("createdAt");
const mutation = useUpdateFleetSquadronMember();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      fleetSquadronSlug: props.squadronSlug,
      username: props.username,
      data: values,
    });
    displaySuccess({ text: t("messages.fleet.squadrons.update.success") });
    comlink.emit("fleet-squadron-members-updated");
    comlink.emit("close-modal");
  } catch (error) {
    const { message, formErrors } = validationErrorFrom(error);
    setErrors(formErrors);
    displayAlert({
      text: message || t("messages.fleet.squadrons.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <Modal :title="t('labels.fleet.members.joined')">
    <form id="squadron-member-date-form" @submit.prevent="onSubmit">
      <FormDatePicker
        v-model="createdAt"
        v-bind="createdAtProps"
        name="createdAt"
        :label="t('labels.fleet.members.joined')"
      />
    </form>
    <template #footer>
      <div class="float-sm-right">
        <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
