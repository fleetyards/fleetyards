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
  useSetInitialPassword as useSetInitialPasswordMutation,
  type ConfirmAccessInput,
  type SetInitialPasswordInput,
} from "@/services/fyApi";
import { useForm } from "vee-validate";
import { csrfToken } from "@/shared/utils/Meta";

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();

const sessionStore = useSessionStore();

const submitting = ref(false);

const confirmed = ref(!!sessionStore.accessConfirmed);

const comlink = useComlink();

const showSetPasswordForm = ref(false);

const isOauthOnly = computed(
  () => sessionStore.currentUser?.oauthOnly ?? false,
);

const authConnections = computed(
  () => sessionStore.currentUser?.authConnections ?? [],
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

// Set initial password form
const setPasswordInitialValues = ref<SetInitialPasswordInput>({
  password: "",
  passwordConfirmation: "",
});

const setPasswordValidationSchema = {
  password: "required|min:8",
  passwordConfirmation: "required|confirmed:@password",
};

const {
  defineField: defineSetPasswordField,
  handleSubmit: handleSetPasswordSubmit,
  resetForm: resetSetPasswordForm,
} = useForm({
  initialValues: setPasswordInitialValues.value,
});

const [newPassword, newPasswordProps] = defineSetPasswordField("password");
const [newPasswordConfirmation, newPasswordConfirmationProps] =
  defineSetPasswordField("passwordConfirmation");

// Comlink for access confirmation events
const accessConfirmationRequiredComlink = ref();

onMounted(() => {
  accessConfirmationRequiredComlink.value = comlink.on(
    "access-confirmation-required",
    resetConfirmation,
  );

  // Check for OAuth callback confirmation via URL params
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get("access_confirmed") === "true") {
    sessionStore.confirmAccess();
    confirmed.value = true;

    // Clean up URL
    const url = new URL(window.location.href);
    url.searchParams.delete("access_confirmed");
    window.history.replaceState({}, "", url.toString());
  }
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

// OAuth re-auth
const confirmViaOAuth = (provider: string) => {
  const form = document.createElement("form");

  form.method = "POST";
  form.action = `/users/auth/${provider}`;

  const csrfInput = document.createElement("input");
  csrfInput.type = "hidden";
  csrfInput.name = "authenticity_token";
  csrfInput.value = csrfToken();
  form.appendChild(csrfInput);

  const originInput = document.createElement("input");
  originInput.type = "hidden";
  originInput.name = "origin";
  originInput.value = `${window.location.origin}/settings/confirm-access-callback`;
  form.appendChild(originInput);

  document.body.appendChild(form);
  form.submit();
  document.body.removeChild(form);
};

// Set initial password
const setInitialPasswordMutation = useSetInitialPasswordMutation();

const setInitialPassword = handleSetPasswordSubmit(async () => {
  submitting.value = true;

  await setInitialPasswordMutation
    .mutateAsync({
      data: {
        password: newPassword.value,
        passwordConfirmation: newPasswordConfirmation.value,
      },
    })
    .then(async () => {
      resetSetPasswordForm();

      submitting.value = false;

      displaySuccess({
        text: t("messages.setInitialPassword.success"),
      });

      sessionStore.confirmAccess();

      confirmed.value = true;
    })
    .catch((error) => {
      console.error(error);

      submitting.value = false;

      displayAlert({
        text: t("messages.setInitialPassword.failure"),
      });
    });
});

const providerLabel = (provider: string) => {
  return provider.charAt(0).toUpperCase() + provider.slice(1);
};
</script>

<template>
  <section class="container confirm-access" data-test="confirm-access">
    <div class="row">
      <div class="col-12">
        <!-- OAuth-only user: show provider buttons -->
        <template v-if="isOauthOnly && !showSetPasswordForm">
          <h1>{{ t("headlines.confirmAccess") }}</h1>

          <div class="oauth-confirm-buttons">
            <Btn
              v-for="provider in authConnections"
              :key="provider"
              :type="BtnTypesEnum.BUTTON"
              :block="true"
              class="oauth-btn"
              data-test="confirm-via-oauth"
              @click="confirmViaOAuth(provider)"
            >
              <i :class="`fa-brands fa-${provider}`" />
              {{
                t("actions.confirmAccessViaProvider", {
                  provider: providerLabel(provider),
                })
              }}
            </Btn>
          </div>

          <div class="set-password-link">
            <a
              href="#"
              data-test="set-password-instead"
              @click.prevent="showSetPasswordForm = true"
            >
              {{ t("actions.setPasswordInstead") }}
            </a>
          </div>
        </template>

        <!-- Set initial password form (OAuth fallback) -->
        <template v-else-if="isOauthOnly && showSetPasswordForm">
          <h1>{{ t("headlines.setInitialPassword") }}</h1>

          <form @submit.prevent="setInitialPassword">
            <FormInput
              v-model="newPassword"
              v-bind="newPasswordProps"
              name="password"
              :rules="setPasswordValidationSchema.password"
              :type="InputTypesEnum.PASSWORD"
              :hide-label-on-empty="true"
              :clearable="true"
              :autofocus="true"
            />

            <FormInput
              v-model="newPasswordConfirmation"
              v-bind="newPasswordConfirmationProps"
              name="passwordConfirmation"
              :rules="setPasswordValidationSchema.passwordConfirmation"
              :type="InputTypesEnum.PASSWORD"
              :hide-label-on-empty="true"
              :clearable="true"
            />

            <Btn
              :loading="submitting"
              :type="BtnTypesEnum.SUBMIT"
              :block="true"
              data-test="submit-set-password"
            >
              {{ t("actions.setPassword") }}
            </Btn>

            <div class="set-password-link">
              <a
                href="#"
                @click.prevent="showSetPasswordForm = false"
              >
                {{ t("actions.back") }}
              </a>
            </div>
          </form>
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

.oauth-confirm-buttons {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.set-password-link {
  margin-top: 1rem;
  text-align: center;
}
</style>
