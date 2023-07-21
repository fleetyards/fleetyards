<template>
  <transition name="fade">
    <div v-if="visible" class="empty-box">
      <Box class="info" :large="true">
        <h1>{{ i18n?.t("headlines.empty") }}</h1>
        <template v-if="isQueryPresent">
          <p>{{ i18n?.t("texts.empty.query") }}</p>
          <div slot="footer" class="empty-box-actions">
            <Btn v-if="isPagePresent" @click.native="resetPage">
              {{ i18n?.t("actions.empty.resetPage") }}
            </Btn>
            <Btn :to="{ name: String(route.name) }" :exact="true">
              {{ i18n?.t("actions.empty.reset") }}
            </Btn>
          </div>
        </template>
        <template v-else>
          <p>
            {{ i18n?.t("texts.empty.info") }}
          </p>
        </template>
      </Box>
    </div>
  </transition>
</template>

<script lang="ts" setup>
import Box from "@/shared/core/components/BaseBox.vue";
import Btn from "@/shared/core/components/BaseBtn.vue";
import { useRoute, useRouter } from "vue-router";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

const i18n = inject("i18n") as I18nPluginOptions;

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
