<script lang="ts">
export default {
  name: "SettingsHangar",
};
</script>

<script lang="ts" setup>
import { useSessionStore } from "@/frontend/stores/session";
import { type UserUpdateInput } from "@/services/fyApi";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useForm } from "vee-validate";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { useUpdateProfile as useUpdateProfileMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess } = useAppNotifications();

const sessionStore = useSessionStore();

const submitting = ref(false);

const initialValues = ref<UserUpdateInput>({
  publicHangar: sessionStore.currentUser?.publicHangar,
  publicHangarLoaners: sessionStore.currentUser?.publicHangarLoaners,
  publicWishlist: sessionStore.currentUser?.publicWishlist,
  hideOwner: sessionStore.currentUser?.hideOwner,
});

const setupForm = () => {
  initialValues.value = {
    publicHangar: sessionStore.currentUser?.publicHangar,
    publicHangarLoaners: sessionStore.currentUser?.publicHangarLoaners,
    publicWishlist: sessionStore.currentUser?.publicWishlist,
    hideOwner: sessionStore.currentUser?.hideOwner,
  };
};

onMounted(() => {
  if (sessionStore.currentUser) {
    setupForm();
  }
});

watch(
  () => sessionStore.currentUser,
  () => {
    setupForm();
  },
);

const comlink = useComlink();

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [publicHangar, publicHangarProps] = defineField("publicHangar");
const [publicHangarLoaners, publicHangarLoanersProps] = defineField(
  "publicHangarLoaners",
);
const [publicWishlist, publicWishlistProps] = defineField("publicWishlist");
const [hideOwner, hideOwnerProps] = defineField("hideOwner");

const mutation = useUpdateProfileMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values,
    })
    .then(() => {
      comlink.emit("user-update");

      displaySuccess({
        text: t("messages.updateHangar.success"),
      });
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-lg-12">
        <h1>{{ t("headlines.settings.hangar") }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="publicHangar"
          v-bind="publicHangarProps"
          name="publicHangar"
          :label="t('labels.user.publicHangar')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="publicHangarLoaners"
          name="publicHangarLoaners"
          v-bind="publicHangarLoanersProps"
          :label="t('labels.user.publicHangarLoaners')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="publicWishlist"
          name="publicWishlist"
          v-bind="publicWishlistProps"
          :label="t('labels.user.publicWishlist')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="hideOwner"
          name="hideOwner"
          v-bind="hideOwnerProps"
          :label="t('labels.user.hideOwner')"
        />
      </div>
    </div>
    <br />
    <Btn
      :loading="submitting"
      :type="BtnTypesEnum.SUBMIT"
      :size="BtnSizesEnum.LARGE"
    >
      {{ t("actions.save") }}
    </Btn>
  </form>
</template>
