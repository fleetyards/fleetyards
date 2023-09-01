<template>
  <transition name="fade">
    <div v-if="visible" class="empty-box">
      <Box class="info" :large="true">
        <h2>{{ t("headlines.empty") }}</h2>
        <template v-if="isQueryPresent">
          <p>{{ t("texts.empty.query") }}</p>
          <slot name="footer">
            <div class="empty-box-actions">
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
            <div class="empty-box-actions">
              <HangarSyncBtn />
              <Btn @click="openGuide">
                {{ t("actions.empty.hangarGuide") }}
              </Btn>
            </div>
          </slot>
        </template>
      </Box>
    </div>
  </transition>
</template>

<script lang="ts" setup>
import Box from "@/shared/components/Box/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarSyncBtn from "@/frontend/components/HangarSyncBtn/index.vue";
import { useRoute, useRouter } from "vue-router";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";
import { extensionUrls } from "@/types/extension";
import { useHangarStore } from "@/frontend/stores/hangar";

const { t } = useI18n();

type Props = {
  visible?: boolean;
  ignoreFilter?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  visible: true,
  ignoreFilter: false,
});

const hangarStore = useHangarStore();

const route = useRoute();

const isPagePresent = computed(
  () => !!route.query.page && Number(route.query.page) > 1,
);

const isQueryPresent = computed(
  () =>
    !props.ignoreFilter &&
    (Object.keys(route.query?.q || {}).length > 0 || isPagePresent.value),
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
  name: "HangarEmptyBox",
};
</script>
