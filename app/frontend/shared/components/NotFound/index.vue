<template>
  <div class="container">
    <Box class="error" :large="true">
      <h1>{{ i18n?.t("headlines.error") }}</h1>
      <p>{{ i18n?.t("texts.error") }}</p>
      <template #footer>
        <Btn :to="{ name: 'home' }" :exact="true">
          <i class="fa fa-chevron-left" />
          {{ i18n?.t("actions.backToHome").toUpperCase() }}
        </Btn>
      </template>
    </Box>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/base/Box/index.vue";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

const i18n = inject<I18nPluginOptions>("i18n");
</script>

<script lang="ts">
export default {
  name: "NotFound",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
