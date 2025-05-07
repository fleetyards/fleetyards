<script lang="ts">
export default {
  name: "EmptyBox",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/Box/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useRoute, useRouter } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

type Props = {
  ignoreFilter?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
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
  <div class="empty-box">
    <Box class="info" large>
      <template #heading>
        {{ t("emptyBox.headline") }}
      </template>
      <template #default>
        <p v-if="isQueryPresent">{{ t("emptyBox.texts.query") }}</p>
        <p v-else>
          {{ t("emptyBox.texts.info") }}
        </p>
      </template>
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
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
