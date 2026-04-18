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
import { useRoute } from "vue-router";
import {
  useConfirmAccess as useConfirmAccessMutation,
  useSendConfirmAccessEmail as useSendConfirmAccessEmailMutation,
  type ConfirmAccessInput,
} from "@/services/fyApi";
import { useForm } from "vee-validate";

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();

const sessionStore = useSessionStore();
const route = useRoute();

const submitting = ref(false);

const confirmed = ref(!!sessionStore.accessConfirmed);

const comlink = useComlink();

const emailSent = ref(false);

const isOauthOnly = computed(
  () => sessionStore.currentUser?.oauthOnly ?? false,
);

const redirectPath = computed(() => {
  return route.path.includes("security") ? "security" : "account";
});

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

  // Check for email confirmation callback via URL params
  const urlParams = new URLSearchParams(window.location.search);
  const accessConfirmed = urlParams.get("access_confirmed");

  if (accessConfirmed === "true") {
    sessionStore.confirmAccess();
    confirmed.value = true;
    cleanUpUrl();
  } else if (accessConfirmed === "invalid") {
    displayAlert({
      text: t("messages.confirmAccessEmail.invalid"),
    });
    cleanUpUrl();
  }
});

onUnmounted(() => {
  accessConfirmationRequiredComlink.value();
});

const cleanUpUrl = () => {
  const url = new URL(window.location.href);
  url.searchParams.delete("access_confirmed");
  window.history.replaceState({}, "", url.toString());
};

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

// Email confirm access
const sendConfirmAccessEmailMutation = useSendConfirmAccessEmailMutation();

const sendConfirmAccessEmail = async () => {
  submitting.value = true;

  await sendConfirmAccessEmailMutation
    .mutateAsync({
      data: {
        redirectPath: redirectPath.value,
      },
    })
    .then(() => {
      submitting.value = false;
      emailSent.value = true;

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
</script>

<template>
  <section class="container confirm-access" data-test="confirm-access">
    <div class="row">
      <div class="col-12">
        <!-- OAuth-only user: email confirmation -->
        <template v-if="isOauthOnly">
          <div class="oauth-confirm-access">
            <h1>{{ t("headlines.confirmAccess") }}</h1>

            <p v-if="emailSent">
              {{ t("messages.confirmAccessEmail.sent") }}
            </p>

            <Btn
              :loading="submitting"
              :disabled="emailSent"
              :type="BtnTypesEnum.BUTTON"
              data-test="send-confirm-access-email"
              @click="sendConfirmAccessEmail"
            >
              {{ t("actions.sendConfirmAccessEmail") }}
            </Btn>
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
