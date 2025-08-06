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

const { displaySuccess, displayAlert } = useAppNotifications();

const { t } = useI18n();

const comlink = useComlink();

const submitting = ref(false);

const form = ref<TwoFactorForm>();

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  form.value = {
    twoFactorCode: null,
  };
};

const router = useRouter();

const disable = async () => {
  submitting.value = true;

  const response = await twoFactorCollection.disable(this.form.twoFactorCode);

  submitting.value = false;

  setupForm();

  if (!response.error) {
    comlink.emit("user-update");

    displaySuccess({
      text: t("messages.twoFactor.disable.success"),
    });

    await router
      .push({ name: "settings-security", hash: "#two-factor" })

      .catch(() => {});
  } else if (response.error === "requires_access_confirmation") {
    comlink.emit("access-confirmation-required");
  } else {
    displayAlert({
      text: t("messages.twoFactor.disable.failure"),
    });
  }
};
</script>

<template>
  <div v-if="currentUser" class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ $t("headlines.settings.twoFactor.disable") }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <p class="text-center">
            {{ $t("texts.twoFactor.disable") }}
          </p>

          <ValidationObserver
            v-if="form"
            v-slot="{ handleSubmit }"
            :slim="true"
          >
            <form
              class="two-factor-form"
              @submit.prevent="handleSubmit(disable)"
            >
              <div class="row">
                <div class="col-12 two-factor-form-inner">
                  <ValidationProvider
                    vid="twoFactorCode"
                    rules="required"
                    :name="$t('labels.twoFactorCode')"
                    :slim="true"
                  >
                    <FormInput
                      id="twoFactorCode"
                      v-model="form.twoFactorCode"
                      class="two-factor-input"
                      :autofocus="true"
                      :no-label="true"
                      translation-key="twoFactorCode"
                    />
                  </ValidationProvider>

                  <br />

                  <Btn :loading="submitting" type="submit" size="large">
                    {{ $t("actions.twoFactor.disable") }}
                  </Btn>
                </div>
              </div>
            </form>
          </ValidationObserver>
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
