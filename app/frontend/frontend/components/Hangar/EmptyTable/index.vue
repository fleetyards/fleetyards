<script lang="ts">
export default {
  name: "HangarEmptyTable",
};
</script>

<script lang="ts" setup>
import Empty from "@/shared/components/Empty/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarSyncBtn from "@/frontend/components/Hangar/SyncBtn/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { extensionUrls } from "@/types/extension";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarStore } from "@/frontend/stores/hangar";

const { t } = useI18n();

const hangarStore = useHangarStore();

const comlink = useComlink();

const openGuide = () => {
  comlink.emit("open-modal", {
    wide: true,
    component: () =>
      import("@/frontend/components/Hangar/GuideModal/index.vue"),
  });
};
</script>

<template>
  <Empty>
    <template #actions>
      <HangarSyncBtn />
      <Btn @click="openGuide">
        {{ t("actions.empty.hangarGuide") }}
      </Btn>
    </template>
    <template #info="{ queryPresent }">
      <div v-if="queryPresent">
        <p>
          {{ t("texts.empty.hangar.info") }}
        </p>
        <div v-if="!hangarStore.extensionReady">
          <p>{{ t("texts.empty.hangar.extension") }}</p>
          <div class="sync-extension-platforms">
            <a
              v-for="link in extensionUrls"
              :key="`extension-link-${link.platform}`"
              v-tooltip="t(`labels.syncExtension.platforms.${link.platform}`)"
              :href="link.url"
              target="_blank"
            >
              <i :class="`fab fa-${link.platform}`" />
            </a>
          </div>
        </div>
      </div>
    </template>
  </Empty>
</template>
