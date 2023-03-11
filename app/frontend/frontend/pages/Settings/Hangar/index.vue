<template>
  <ValidationObserver v-if="form" v-slot="{ handleSubmit }" :slim="true">
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ $t("headlines.settings.hangar") }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="publicHangar"
            :name="$t('labels.user.publicHangar')"
            :slim="true"
          >
            <Checkbox
              id="publicHangar"
              v-model="form.publicHangar"
              :label="$t('labels.user.publicHangar')"
              :class="{ 'has-error has-feedback': errors[0] }"
            />
          </ValidationProvider>
        </div>
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="publicHangarLoaners"
            :name="$t('labels.user.publicHangarLoaners')"
            :slim="true"
          >
            <Checkbox
              id="publicHangarLoaners"
              v-model="form.publicHangarLoaners"
              :label="$t('labels.user.publicHangarLoaners')"
              :class="{ 'has-error has-feedback': errors[0] }"
            />
          </ValidationProvider>
        </div>
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="publicWishlist"
            :name="$t('labels.user.publicWishlist')"
            :slim="true"
          >
            <Checkbox
              id="publicWishlist"
              v-model="form.publicWishlist"
              :label="$t('labels.user.publicWishlist')"
              :class="{ 'has-error has-feedback': errors[0] }"
            />
          </ValidationProvider>
        </div>
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="hideOwner"
            :name="$t('labels.user.hideOwner')"
            :slim="true"
          >
            <Checkbox
              id="hideOwner"
              v-model="form.hideOwner"
              :label="$t('labels.user.hideOwner')"
              :class="{ 'has-error has-feedback': errors[0] }"
            />
          </ValidationProvider>
        </div>
      </div>
      <br />
      <Btn :loading="submitting" type="submit" size="large">
        {{ $t("actions.save") }}
      </Btn>
    </form>
  </ValidationObserver>
</template>

<script lang="ts" setup>
import { ref, watch } from "vue";
import { displaySuccess } from "@/frontend/lib/Noty";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Checkbox from "@/frontend/core/components/Form/Checkbox/index.vue";
import userCollection from "@/frontend/api/collections/User";
import { useSessionStore } from "@/frontend/stores/Session";
import { useComlink } from "@/frontend/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";

const form = ref<TNotificationSettingsForm | null>(null);

const submitting = ref(false);

const sessionStore = useSessionStore();

const setupForm = () => {
  form.value = {
    publicHangar: sessionStore.currentUser?.publicHangar,
    publicHangarLoaners: sessionStore.currentUser?.publicHangarLoaners,
    publicWishlist: sessionStore.currentUser?.publicWishlist,
    hideOwner: sessionStore.currentUser?.hideOwner,
  };
};

if (sessionStore.currentUser) {
  setupForm();
}

watch(
  () => sessionStore.currentUser,
  () => {
    setupForm();
  }
);

const comlink = useComlink();

const { t } = useI18n();

const submit = async () => {
  submitting.value = true;

  const response = await userCollection.updateProfile(form.value);

  submitting.value = false;

  if (!(response as TRecordErrorResponse).error) {
    comlink.$emit("user-update");

    displaySuccess({
      text: t("messages.updateHangar.success"),
    });
  }
};
</script>

<script lang="ts">
export default {
  name: "SettingsHangarPage",
};
