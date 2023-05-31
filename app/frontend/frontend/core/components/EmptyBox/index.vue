<template>
  <transition name="fade">
    <div v-if="visible" class="empty-box">
      <Box class="info" :large="true">
        <h1>{{ t("headlines.empty") }}</h1>
        <p v-if="isQueryPresent">{{ t("texts.empty.query") }}</p>
        <p v-else>
          {{ t("texts.empty.info") }}
        </p>
        <template #footer>
          <div v-if="isQueryPresent" class="empty-box-actions">
            <Btn v-if="isPagePresent" @click="resetPage">
              {{ t("actions.empty.resetPage") }}
            </Btn>
            <Btn :to="{ name: String(route.name) }" :exact="true">
              {{ t("actions.empty.reset") }}
            </Btn>
          </div>
        </template>
      </Box>
    </div>
  </transition>
</template>

<script lang="ts" setup>
import Box from "@/frontend/core/components/Box/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { useRoute, useRouter } from "vue-router";
import { useI18n } from "@/frontend/composables/useI18n";

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
  () => !!route.query.page && Number(route.query.page) > 1
);

const isQueryPresent = computed(
  () =>
    !props.ignoreFilter &&
    (Object.keys(route.query?.q || {}).length > 0 || isPagePresent.value)
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

<script lang="ts">
export default {
  name: "EmptyBox",
};
</script>
