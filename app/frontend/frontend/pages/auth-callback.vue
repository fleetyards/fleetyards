<script lang="ts">
export default {
  name: "AuthCallbackPage",
};
</script>

<script lang="ts" setup>
import { useRedirectBack } from "@/shared/composables/useRedirectBack";

const { handleRedirect } = useRedirectBack();

onMounted(async () => {
  await handleRedirect();
});
</script>

<template>
  <div></div>
</template>
