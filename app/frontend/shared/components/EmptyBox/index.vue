<script lang="ts">
export default {
  name: "EmptyBox",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/base/Box/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useRoute, useRouter } from "vue-router";
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
</script>

<template>
  <transition name="fade">
    <div v-if="visible" class="empty-box">
      <Box class="info" :large="true">
        <h1>{{ t("emptyBox.headline") }}</h1>
        <p v-if="isQueryPresent">{{ t("emptyBox.texts.query") }}</p>
        <p v-else>
          {{ t("emptyBox.texts.info") }}
        </p>
        <template v-if="isQueryPresent" #footer>
          <div class="empty-box-actions">
            <Btn v-if="isPagePresent" @click="resetPage">
              {{ t("emptyBox.actions.resetPage") }}
            </Btn>
            <Btn :to="{ name: String(route.name) }" route-active-class="">
              {{ t("emptyBox.actions.reset") }}
            </Btn>
          </div>
        </template>
      </Box>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
