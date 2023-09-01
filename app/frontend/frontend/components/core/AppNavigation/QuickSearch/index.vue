<template>
  <div v-if="quickSearchKey" class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        :id="id"
        v-model="form[quickSearchKey]"
        :translation-key="`quicksearch.${String(route.name)}`"
        :no-label="true"
        :autofocus="!mobile"
        :clearable="true"
      />
    </form>
  </div>
</template>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useFilters } from "@/shared/composables/useFilters";

const { filter } = useFilters();

type QuickSearchFormData = {
  [key: string]: string;
};

const form = ref<QuickSearchFormData>({});

const mobile = useMobile();

const route = useRoute();

const id = computed<string>(() => {
  return String(route.meta.quickSearch || "quicksearch");
});

const quickSearchKey = computed(() => {
  if (!route.meta.quickSearch) {
    return undefined;
  }

  return String(route.meta.quickSearch);
});

const setupForm = () => {
  if (!quickSearchKey.value) {
    return;
  }

  const query = queryParams();

  query[quickSearchKey.value] = query[quickSearchKey.value] || undefined;

  form.value = query;
};

onMounted(() => {
  setupForm();
});

watch(
  () => route,
  () => {
    setupForm();
  },
  {
    deep: true,
  },
);

const queryParams = () => {
  return JSON.parse(JSON.stringify(route.query.q || {}));
};
</script>

<script lang="ts">
export default {
  name: "AppNavigationQuickSearch",
};
</script>
