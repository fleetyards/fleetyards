<script lang="ts">
export default {
  name: "MemberModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { transformErrors } from "@/frontend/utils/transformErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Fleet,
  type FleetMemberCreateInput,
  type ValidationError,
} from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useCreateFleetMember as useCreateFleetMemberMutation } from "@/services/fyApi";
import { type ErrorType } from "@/services/axiosClient";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

const { t } = useI18n();

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const submitting = ref(false);

const validationSchema = {
  username: "required|alpha_dash|user",
};

const { displayAlert } = useAppNotifications();

const { defineField, handleSubmit, setErrors } =
  useForm<FleetMemberCreateInput>({
    initialValues: {
      username: undefined,
    },
  });

const [username, usernameProps] = defineField("username");

const comlink = useComlink();

const mutation = useCreateFleetMemberMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      data: values,
    })
    .then((member) => {
      comlink.emit("fleet-member-invited", member);
      comlink.emit("close-modal");
    })
    .catch((error) => {
      const response = error as unknown as ErrorType<ValidationError>;

      if (response.response?.data?.errors) {
        setErrors(
          transformErrors(response.response.data.errors, {
            user_id: "username",
          }),
        );

        displayAlert({
          text: response.response?.data?.message,
        });
      } else {
        displayAlert({
          text: response.response?.data?.message,
        });
      }
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal v-if="fleet" :title="t('headlines.fleets.inviteMember')">
    <form :id="`fleet-member-${fleet.id}`" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12">
          <FormInput
            v-model="username"
            v-bind="usernameProps"
            :rules="validationSchema.username"
            name="username"
            :no-label="true"
            :autofocus="true"
          />
        </div>
      </div>
    </form>
    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LARGE"
          :inline="true"
          @click="onSubmit"
        >
          {{ t("actions.fleet.members.invite") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
