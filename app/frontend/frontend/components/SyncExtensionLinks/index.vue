<script lang="ts">
export default {
  name: "SyncExtensionLinks",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { extensionUrls } from "@/types/extension";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // Smaller icons, left-aligned with the text around them rather than the
  // centrepiece of an otherwise empty screen.
  compact?: boolean;
  // One row per store, named, for a dialog that is about getting the
  // extension: the icons alone left the reader guessing which was which.
  list?: boolean;
  // The extension is installed but too old, so the rows offer an update.
  update?: boolean;
};

withDefaults(defineProps<Props>(), {
  compact: false,
  list: false,
  update: false,
});

const { t } = useI18n();
</script>

<template>
  <ul
    v-if="list"
    class="sync-extension-stores"
    data-test="sync-extension-links"
  >
    <li
      v-for="link in extensionUrls"
      :key="link.platform"
      class="sync-extension-stores__row"
    >
      <i
        :class="`fa-brands fa-${link.platform}`"
        class="sync-extension-stores__icon"
        aria-hidden="true"
      />
      <span class="sync-extension-stores__name">
        {{ t(`labels.syncExtension.platforms.${link.platform}`) }}
      </span>
      <Btn
        :href="link.url"
        target="_blank"
        :variant="BtnVariantsEnum.GHOST"
        :data-test="`sync-extension-store-${link.platform}`"
      >
        {{
          update
            ? t("actions.syncExtension.updateExtension")
            : t("actions.syncExtension.addExtension")
        }}
        <i class="fa-light fa-arrow-up-right-from-square" />
      </Btn>
    </li>
  </ul>
  <div
    v-else
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

<style lang="scss" scoped>
.sync-extension-stores {
  margin: 0;
  padding: 0;
  list-style: none;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
}

.sync-extension-stores__row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 8px 8px 14px;

  & + & {
    border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  }
}

.sync-extension-stores__icon {
  flex-shrink: 0;
  width: 28px;
  font-size: 24px;
  text-align: center;
}

.sync-extension-stores__name {
  flex: 1 1 auto;
  min-width: 0;
  color: var(--color-lifted, #eee);
}
</style>
