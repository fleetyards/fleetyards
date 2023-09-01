<template>
  <div class="empty-table">
    <h2>{{ t("headlines.empty") }}</h2>
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
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useRoute, useRouter } from "vue-router";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

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
  name: "WishlistEmptyTable",
};
</script>
