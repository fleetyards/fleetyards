<script lang="ts">
import { enabledRouteGuard } from "@/frontend/utils/RouteGuards/TwoFactor";

export default {
  name: "TwoFactorDisable",
  beforeRouteEnter: enabledRouteGuard,
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useForm } from "vee-validate";
import {
  useDisableOtpSetup as useDisableOtpSetupMutation,
  type ValidationError,
} from "@/services/fyApi";
import { type ErrorType } from "@/services/axiosClient";

const { displaySuccess, displayAlert } = useAppNotifications();

const { t } = useI18n();

const comlink = useComlink();

const sessionStore = useSessionStore();
const { currentUser } = storeToRefs(sessionStore);

const submitting = ref(false);

const validationSchema = {
  twoFactorCode: "required",
};

const { defineField, handleSubmit } = useForm();

const [twoFactorCode, twoFactorCodeProps] = defineField("twoFactorCode");

const router = useRouter();

const disableMutation = useDisableOtpSetupMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await disableMutation
    .mutateAsync({
      data: values,
    })
    .then(() => {
      comlink.emit("user-update");

      displaySuccess({
        text: t("messages.twoFactor.disable.success"),
      });

      router
        .push({ name: "settings-security", hash: "#two-factor" })
        .catch(() => {});
    })
    .catch((error) => {
      const response = error as unknown as ErrorType<ValidationError>;

      if (response.code === "requires_access_confirmation") {
        comlink.emit("access-confirmation-required");
      } else {
        displayAlert({
          text: t("messages.twoFactor.disable.failure"),
        });
      }
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <div v-if="currentUser" class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ t("headlines.settings.twoFactor.disable") }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <p class="text-center">
            {{ t("texts.twoFactor.disable") }}
          </p>

          <form class="two-factor-form" @submit.prevent="onSubmit">
            <div class="row">
              <div class="col-12 two-factor-form-inner">
                <FormInput
                  v-model="twoFactorCode"
                  name="twoFactorCode"
                  v-bind="twoFactorCodeProps"
                  :rules="validationSchema.twoFactorCode"
                  class="two-factor-input"
                  :autofocus="true"
                  :no-label="true"
                  translation-key="twoFactorCode"
                />

                <br />

                <Btn :loading="submitting" type="submit" size="large">
                  {{ t("actions.twoFactor.disable") }}
                </Btn>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.two-factor-form {
  display: flex;
  justify-content: center;
  margin: 40px 0;

  .two-factor-form-inner {
    width: 300px;
  }
}

.two-factor-form-inner {
  display: flex;
  flex-direction: column;
}
</style>
