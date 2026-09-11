<script lang="ts">
export default {
  name: "MemberNicknameModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type FleetMember,
  type FleetMemberUpdateInput,
  useUpdateFleetMember as useUpdateFleetMemberMutation,
} from "@/services/fyApi";

const { t } = useI18n();

type Props = {
  fleetSlug: string;
  member: FleetMember;
};

const props = defineProps<Props>();

const submitting = ref(false);

const validationSchema = {
  nickname: "max:255",
};

const { displaySuccess, displayAlert } = useAppNotifications();

const { defineField, handleSubmit, setErrors } =
  useForm<FleetMemberUpdateInput>({
    initialValues: {
      nickname: props.member.nickname ?? undefined,
    },
  });

const [nickname, nicknameProps] = defineField("nickname");

const comlink = useComlink();

const mutation = useUpdateFleetMemberMutation();

// An empty field clears the nickname rather than storing "": the server
// normalizes blank to null, and sending null says so explicitly.
const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      fleetSlug: props.fleetSlug,
      username: props.member.username,
      data: { nickname: values.nickname || null },
    })
    .then(() => {
      comlink.emit("fleet-member-update");
      comlink.emit("close-modal");

      displaySuccess({
        text: t("messages.fleet.members.nickname.success"),
      });
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({
        text: message || t("messages.fleet.members.nickname.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal v-if="member" :title="t('headlines.fleets.memberNickname')">
    <form :id="`fleet-member-nickname-${member.id}`" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12">
          <FormInput
            v-model="nickname"
            v-bind="nicknameProps"
            :rules="validationSchema.nickname"
            :placeholder="member.username"
            name="nickname"
            :no-label="true"
            :autofocus="true"
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
