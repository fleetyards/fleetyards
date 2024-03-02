<template>
  <div class="empty-table">
    <h2>{{ t("headlines.empty") }}</h2>
    <template v-if="isQueryPresent">
      <p>{{ t("texts.empty.query") }}</p>
      <slot name="footer">
        <div class="empty-table-actions">
          <Btn @click="openGuide">
            {{ t("actions.empty.hangarGuide") }}
          </Btn>
          <Btn v-if="isPagePresent" @click="resetPage">
            {{ t("actions.empty.resetPage") }}
          </Btn>
          <Btn :to="{ name: String(route.name) }" :exact="true">
            {{ t("actions.empty.reset") }}
          </Btn>
        </div>
      </slot>
    </template>
    <template v-else>
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
      <slot name="footer">
        <div class="empty-table-actions">
          <HangarSyncBtn />
          <Btn @click="openGuide">
            {{ t("actions.empty.hangarGuide") }}
          </Btn>
        </div>
      </slot>
    </template>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarSyncBtn from "@/frontend/components/HangarSyncBtn/index.vue";
import { useRoute, useRouter } from "vue-router";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarStore } from "@/frontend/stores/hangar";

const { t } = useI18n();

const hangarStore = useHangarStore();

const extensionUrls = computed(() => [
  {
    platform: "chrome",
    url: "https://chrome.google.com/webstore/detail/fleetyards-sync/glchfaleieoljcimjjkdkeifnejbcokg",
  },
  {
    platform: "firefox",
    url: "https://addons.mozilla.org/de/firefox/addon/fleetyards-sync/",
  },
  {
    platform: "github",
    url: "https://github.com/fleetyards/sync/releases",
  },
]);

const route = useRoute();

const isPagePresent = computed(
  () => !!route.query.page && Number(route.query.page) > 1,
);

const isQueryPresent = computed(
  () => Object.keys(route.query?.q || {}).length > 0 || isPagePresent.value,
);

const router = useRouter();

const resetPage = () => {
  const query = {
    ...JSON.parse(JSON.stringify(route.query)),
  };

  if (query.page) {
    delete query.page;
  }

  router
    .replace({
      name: String(route.name),
      query: {
        ...query,
        q: route.query.q || {},
      },
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch((_err) => {});
};

const comlink = useComlink();

const openGuide = () => {
  comlink.emit("open-modal", {
    wide: true,
    component: () => import("@/frontend/components/HangarGuideModal/index.vue"),
  });
};
</script>

<script lang="ts">
export default {
  name: "HangarEmptyTable",
};
</script>
