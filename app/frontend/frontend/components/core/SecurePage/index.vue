<template>
  <section class="container confirm-access" data-test="confirm-access">
    <div class="row">
      <div class="col-12">
        <form @submit.prevent="confirmAccess">
          <h1>{{ t("headlines.confirmAccess") }}</h1>

          <FormInput
            v-model="password"
            name="password"
            type="password"
            :autofocus="true"
          />

          <Btn
            :loading="submitting"
            type="submit"
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

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useComlink } from "@/shared/composables/useComlink";
import { useSessionQueries } from "@/frontend/composables/useSessionQueries";
import { useForm } from "vee-validate";

const { t } = useI18n();
const { displayAlert } = useNoty();

const sessionStore = useSessionStore();

const submitting = ref(false);

const confirmed = ref(!!sessionStore.accessConfirmed);

// metaTitle = computed(() => {
//   return t(`title.confirmAccess`);
// });

const comlink = useComlink();

const validationSchema = {
  password: "required",
};

const { useFieldModel, handleSubmit } = useForm({ validationSchema });

const [password] = useFieldModel(["password"]);

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

const { confirmAccessMutation } = useSessionQueries();

const confirmAccess = handleSubmit(async () => {
  submitting.value = true;

  try {
    await confirmAccessMutation.mutate({
      password: password.value,
    });

    password.value = undefined;
    submitting.value = false;

    await sessionStore.confirmAccess();

    confirmed.value = true;
  } catch (error) {
    displayAlert({
      text: t("messages.confirmAccess.failure"),
    });
  }
});
</script>

<script lang="ts">
export default {
  name: "SecurePage",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
