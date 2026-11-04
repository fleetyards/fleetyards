<script lang="ts">
export default {
  name: "WebglFallback",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <div class="webgl-fallback" data-test="webgl-fallback">
    <i class="fa-light fa-cube" />
    <p>{{ t("messages.holoViewer.webglNotSupported") }}</p>
  </div>
</template>

<style lang="scss" scoped>
.webgl-fallback {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  min-height: inherit;
  color: var(--body-muted);

  i {
    margin-bottom: 10px;
    font-size: 2rem;
  }

  p {
    margin: 0;
  }
}
</style>
