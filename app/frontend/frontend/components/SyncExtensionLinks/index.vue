<script lang="ts">
export default {
  name: "SyncExtensionLinks",
};
</script>

<script lang="ts" setup>
import { extensionUrls } from "@/types/extension";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // Smaller icons, left-aligned with the text around them rather than the
  // centrepiece of an otherwise empty screen.
  compact?: boolean;
};

withDefaults(defineProps<Props>(), {
  compact: false,
});

const { t } = useI18n();
</script>

<template>
  <div
    class="sync-extension-platforms"
    :class="{ 'sync-extension-platforms--compact': compact }"
    data-test="sync-extension-links"
  >
    <a
      v-for="link in extensionUrls"
      :key="link.platform"
      v-tooltip="t(`labels.syncExtension.platforms.${link.platform}`)"
      :aria-label="t(`labels.syncExtension.platforms.${link.platform}`)"
      :href="link.url"
      target="_blank"
      rel="noopener"
    >
      <i :class="`fa-brands fa-${link.platform}`" />
    </a>
  </div>
</template>
