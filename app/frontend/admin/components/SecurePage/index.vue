<script lang="ts">
export default {
  name: "SecurePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useSessionStore } from "@/admin/stores/session";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import {
  useConfirmAccess as useConfirmAccessMutation,
  type ConfirmAccessInput,
} from "@/services/fyApi";
import { useForm } from "vee-validate";

const { t } = useI18n();
const { displayAlert } = useAppNotifications();

const sessionStore = useSessionStore();

const submitting = ref(false);

const confirmed = ref(!!sessionStore.accessConfirmed);

// metaTitle = computed(() => {
//   return t(`title.confirmAccess`);
// });

const comlink = useComlink();

const initialValues = ref<ConfirmAccessInput>({
  password: "",
});

const validationSchema = {
  password: "required",
};

const { defineField, handleSubmit, resetForm } = useForm({
  initialValues: initialValues.value,
});

const [password, passwordProps] = defineField("password");

onMounted(() => {
  comlink.on("access-confirmation-required", resetConfirmation);
});

onUnmounted(() => {
  comlink.off("access-confirmation-required");
});

watch(
  () => confirmed.value,
  () => {
    if (confirmed.value) {
      comlink.emit("access-confirmed");
    }
  },
);

const resetConfirmation = () => {
  confirmed.value = false;
  sessionStore.resetConfirmAccess();
};

const confirmAccessMutation = useConfirmAccessMutation();

const confirmAccess = handleSubmit(async () => {
  submitting.value = true;

  await confirmAccessMutation
    .mutateAsync({
      data: {
        password: password.value,
      },
    })
    .then(async () => {
      resetForm();

      submitting.value = false;

      await sessionStore.confirmAccess();

      confirmed.value = true;
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: t("messages.confirmAccess.failure"),
      });
    });
});
</script>

<template>
  <section class="container confirm-access" data-test="confirm-access">
    <div class="row">
      <div class="col-12">
        <form @submit.prevent="confirmAccess">
          <h1>{{ t("headlines.confirmAccess") }}</h1>

          <FormInput
            v-model="password"
            v-bind="passwordProps"
            name="password"
            :rules="validationSchema.password"
            :type="InputTypesEnum.PASSWORD"
            :hide-label-on-empty="true"
            :clearable="true"
            :autofocus="true"
          />

          <Btn
            :loading="submitting"
            :type="BtnTypesEnum.SUBMIT"
            :class="{ confirmed: confirmed }"
            data-test="submit-confirm-access"
            :block="true"
          >
            {{ t("actions.confirmAccess") }}
          </Btn>
        </form>
      </div>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
