<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        :id="route.meta?.search || 'search'"
        v-model="form[route.meta?.search]"
        :translation-key="`search.${$route.name}`"
        :no-label="true"
        :autofocus="!mobile"
      />
    </form>
  </div>
</template>

<script lang="ts" setup>
import { useRoute, useRouter } from "vue-router/composables";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { debounce } from "ts-debounce";
import { storeToRefs } from "pinia";
import { useAppStore } from "@/frontend/stores/App";

type SearchFormType = {
  [key: string]: string;
};

const form = ref<SearchFormType>({});

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

onMounted(() => {
  setupSearch();
});

watch(
  () => form.value,
  () => {
    filter();
  },
  {
    deep: true,
  }
);

const route = useRoute();

watch(
  () => route,
  () => {
    setupSearch();
  },
  {
    deep: true,
  }
);

const setupSearch = () => {
  form.value = {
    [route.meta?.search as string]: route.query[
      route.meta?.search as string
    ] as string,
  };
};

const router = useRouter();

const debouncedFilter = () => {
  const query = {
    ...route.query,
    ...form.value,
  };

  if (!query[route.meta?.search]) {
    delete query[route.meta?.search];
  }

  router
    .replace({
      name: route.name || undefined,
      query,
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch((_err: Error) => {});
};

const filter = () => {
  debounce(debouncedFilter, 500);
};
</script>

<script lang="ts">
export default {
  name: "SearchForm",
};
</script>
