<template>
  <transition name="fade">
    <div v-if="visible" class="empty-box">
      <Box class="info" :large="true">
        <h1>{{ t("headlines.empty") }}</h1>
        <template v-if="isQueryPresent">
          <p>{{ t("texts.empty.query") }}</p>
          <div slot="footer" class="empty-box-actions">
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
            {{ t("texts.empty.wishlist.info") }}
          </p>
          <div slot="footer" class="empty-box-actions">
            <Btn @click.native="openGuide">
              {{ t("actions.empty.hangarGuide") }}
            </Btn>
          </div>
        </template>
      </Box>
    </div>
  </transition>
</template>

<script lang="ts" setup>
import Box from "@/shared/components/base/Box/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useRoute, useRouter } from "vue-router";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

type Props = {
  visible?: boolean;
  ignoreFilter?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  visible: true,
  ignoreFilter: false,
});

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
  comlink.$emit("open-modal", {
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
