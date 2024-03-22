<template>
  <div class="container">
    <Box class="error" :large="true">
      <h1>{{ t("headlines.error") }}</h1>
      <p>{{ t("texts.error") }}</p>
      <template #footer>
        <Btn :to="{ name: 'home' }" :exact="true">
          <i class="fa fa-chevron-left" />
          {{ t("actions.backToHome").toUpperCase() }}
        </Btn>
      </template>
    </Box>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/base/Box/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "NotFound",
};
</script>

<style lang="scss" scoped>
@import "404";
</style>
