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
import { useSessionStore } from "@/frontend/stores/session";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import {
  useConfirmAccess as useConfirmAccessMutation,
  useSendConfirmAccessEmail as useSendConfirmAccessEmailMutation,
  useVerifyConfirmAccessCode as useVerifyConfirmAccessCodeMutation,
  type ConfirmAccessInput,
} from "@/services/fyApi";
import { useForm } from "vee-validate";

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();

const sessionStore = useSessionStore();

const submitting = ref(false);

const confirmed = ref(!!sessionStore.accessConfirmed);

const comlink = useComlink();

const emailSent = ref(false);
const emailToken = ref("");
const confirmationCode = ref("");

const isOauthOnly = computed(
  () => sessionStore.currentUser?.oauthOnly ?? false,
);

// Password confirmation form
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

// Comlink for access confirmation events
const accessConfirmationRequiredComlink = ref();

onMounted(() => {
  accessConfirmationRequiredComlink.value = comlink.on(
    "access-confirmation-required",
    resetConfirmation,
  );
});

onUnmounted(() => {
  accessConfirmationRequiredComlink.value();
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

// Password confirm access
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

      sessionStore.confirmAccess();

      confirmed.value = true;
    })
    .catch((error) => {
      console.error(error);

      submitting.value = false;

      displayAlert({
        text: t("messages.confirmAccess.failure"),
      });
    });
});

// Email code confirm access
const sendConfirmAccessEmailMutation = useSendConfirmAccessEmailMutation();
const verifyConfirmAccessCodeMutation = useVerifyConfirmAccessCodeMutation();

const sendConfirmAccessEmail = async () => {
  submitting.value = true;

  await sendConfirmAccessEmailMutation
    .mutateAsync({})
    .then((response) => {
      submitting.value = false;
      emailSent.value = true;
      emailToken.value = response.token;

      displaySuccess({
        text: t("messages.confirmAccessEmail.sent"),
      });
    })
    .catch((error) => {
      console.error(error);

      submitting.value = false;

      displayAlert({
        text: t("messages.confirmAccessEmail.failure"),
      });
    });
};

const verifyConfirmAccessCode = async () => {
  if (!confirmationCode.value) return;

  submitting.value = true;

  await verifyConfirmAccessCodeMutation
    .mutateAsync({
      data: {
        token: emailToken.value,
        confirmationCode: confirmationCode.value,
      },
    })
    .then(() => {
      submitting.value = false;

      sessionStore.confirmAccess();

      confirmed.value = true;
    })
    .catch((error) => {
      console.error(error);

      submitting.value = false;

      displayAlert({
        text: t("messages.confirmAccessCode.failure"),
      });
    });
};
</script>

<template>
  <section class="container confirm-access" data-test="confirm-access">
    <div class="row">
      <div class="col-12">
        <!-- OAuth-only user: email code confirmation -->
        <template v-if="isOauthOnly">
          <div class="oauth-confirm-access">
            <h1>{{ t("headlines.confirmAccess") }}</h1>

            <template v-if="!emailSent">
              <Btn
                :loading="submitting"
                :type="BtnTypesEnum.BUTTON"
                :block="true"
                data-test="send-confirm-access-email"
                @click="sendConfirmAccessEmail"
              >
                {{ t("actions.sendConfirmAccessEmail") }}
              </Btn>
            </template>

            <template v-else>
              <p>{{ t("messages.confirmAccessEmail.sent") }}</p>

              <form @submit.prevent="verifyConfirmAccessCode">
                <FormInput
                  v-model="confirmationCode"
                  name="confirmationCode"
                  rules="required|min:6|max:6"
                  :type="InputTypesEnum.TEXT"
                  :hide-label-on-empty="true"
                  :clearable="true"
                  :autofocus="true"
                />

                <Btn
                  :loading="submitting"
                  :type="BtnTypesEnum.SUBMIT"
                  :block="true"
                  data-test="submit-confirm-access-code"
                >
                  {{ t("actions.confirmAccess") }}
                </Btn>
              </form>
            </template>
          </div>
        </template>

        <!-- Regular user: password confirmation -->
        <template v-else>
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
        </template>
      </div>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
