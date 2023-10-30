<template>
  <div class="empty-table">
    <h2>{{ t("headlines.empty") }}</h2>
    <template v-if="isQueryPresent">
      <p>{{ t("texts.empty.query") }}</p>
      <div slot="footer" class="empty-table-actions">
        <Btn @click.native="openGuide">
          {{ t("actions.empty.hangarGuide") }}
        </Btn>
        <Btn v-if="isPagePresent" @click.native="resetPage">
          {{ t("actions.empty.resetPage") }}
        </Btn>
        <Btn :to="{ name: String(route.name) }" :exact="true">
          {{ t("actions.empty.reset") }}
        </Btn>
      </div>
    </template>
    <template v-else>
      <p>
        {{ t("texts.empty.hangar.info") }}
      </p>
      <div v-if="!extensionReady">
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
      <div slot="footer" class="empty-table-actions">
        <HangarSyncBtn />
        <Btn @click.native="openGuide">
          {{ t("actions.empty.hangarGuide") }}
        </Btn>
      </div>
    </template>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import HangarSyncBtn from "@/frontend/components/HangarSyncBtn/index.vue";
import { useRoute, useRouter } from "vue-router/composables";
import { useComlink } from "@/frontend/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";

const { t } = useI18n();

const extensionReady = computed(() => Store.getters["hangar/extensionReady"]);

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
  comlink.$emit("open-modal", {
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
