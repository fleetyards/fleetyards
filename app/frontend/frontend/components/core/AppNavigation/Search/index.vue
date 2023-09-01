<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        :id="$route.meta.search || 'search'"
        v-model="form[route.meta.search]"
        :translation-key="`search.${route.name}`"
        :no-label="true"
        :autofocus="!mobile"
      />
    </form>
  </div>
</template>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { debounce } from "ts-debounce";
import { useMobile } from "@/shared/composables/useMobile";

type SearchFormType = {
  [key: string]: string;
};

const form = ref<SearchFormType>({});

const debouncedFilter = debounce(filter, 500);

const mobile = useMobile();

onMounted(() => {
  setupSearch();
});

watch(
  () => form.value,
  () => {
    debouncedFilter();
  },
  {
    deep: true,
  },
);

const route = useRoute();

watch(
  () => route.query,
  () => {
    setupSearch();
  },
  {
    deep: true,
  },
);

const setupSearch = () => {
  form.value = {
    [route.meta.search]: route.query[route.meta.search] || null,
  };
};

const router = useRouter();

const filter = () => {
  const query = {
    ...route.query,
    ...form.value,
  };

  if (!query[route.meta.search]) {
    delete query[route.meta.search];
  }

  router
    .replace({
      name: route.name || undefined,
      query,
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch((_err) => {});
};
</script>

<script lang="ts">
export default {
  name: "AppNavigationSearchForm",
};
</script>
