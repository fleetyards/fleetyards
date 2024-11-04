<template>
  <div />
</template>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useRoute, useRouter } from "vue-router";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty();

onMounted(() => {
  fetch();
});

const route = useRoute();

const router = useRouter();

const fetch = async () => {
  const response = await this.$api.post("users/confirm", {
    token: route.params.token,
  });

  if (!response.error) {
    this.$comlink.$emit("user-update");

    displaySuccess({
      text: t("messages.accountConfirm.success"),
    });

    await this.$store.dispatch("hangar/enableStarterGuide");
  } else {
    displayAlert({
      text: t("messages.accountConfirm.failure"),
    });
  }

  // eslint-disable-next-line @typescript-eslint/no-empty-function
  router.push("/").catch(() => {});
};
</script>

<script lang="ts">
export default {
  name: "ConfirmAccountPage",
};
</script>
