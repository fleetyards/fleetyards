<script lang="ts">
export default {
  name: "AppModalCloseBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <Btn :aria-label="t('actions.close')" v-tooltip="t('actions.close')">
    <i class="fa-light fa-times" />
  </Btn>
</template>
