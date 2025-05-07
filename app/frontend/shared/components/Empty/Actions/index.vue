<script lang="ts">
export default {
  name: "EmptyActions",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  pagePresent: boolean;
  queryPresent: boolean;
};

defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

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

const reset = () => {
  router
    .replace({
      name: String(route.name),
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch((_err) => {});
};
</script>

<template>
  <div class="empty__actions">
    <slot></slot>
    <template v-if="queryPresent">
      <Btn v-if="pagePresent" @click="resetPage">
        {{ t("emptyBox.actions.resetPage") }}
      </Btn>
      <Btn @click="reset">
        {{ t("emptyBox.actions.reset") }}
      </Btn>
    </template>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
