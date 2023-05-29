<template>
  <div class="quick-search-bar">
    <form
      @submit.prevent="
        () => {
          filter;
        }
      "
    >
      <FormInput
        :id="route.meta?.quickSearch || 'quicksearch'"
        v-model="quickSearch"
        :translation-key="`quicksearch.${route.name}`"
        :no-label="true"
        :autofocus="!mobile"
        :clearable="true"
      />
    </form>
  </div>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { storeToRefs } from "pinia";
import { useAppStore } from "@/frontend/stores/App";
import { useFilters } from "@/frontend/composables/useFilters";

type QuickSearchFormData = {
  [key: string]: string;
};

const route = useRoute();

const query = computed(() => (route.query.q || {}) as QuickSearchFormData);

const { filter, updateFilter } = useFilters({
  [route.meta?.quickSearch]: query.value[route.meta?.quickSearch],
});

const quickSearch = ref("");

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

onMounted(() => {
  update();
});

const update = () => {
  updateFilter({
    [route.meta?.quickSearch]: query.value[route.meta?.quickSearch],
  });
};

watch(
  () => route,
  () => {
    update();
  },
  { deep: true }
);
</script>

<script lang="ts">
export default {
  name: "QuickSearch",
};
</script>
