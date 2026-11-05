<script lang="ts">
export default {
  name: "FleetsTitleFilterForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useFilters } from "@/shared/composables/useFilters";
import { useI18n } from "@/shared/composables/useI18n";

interface TitleQuery {
  titleCont?: string;
}

const { t } = useI18n();

const setupForm = () => {
  form.value = { titleCont: filters.value.titleCont };
};

const { filter, filters } = useFilters<TitleQuery>({
  updateCallback: setupForm,
});

const form = ref<TitleQuery>({ titleCont: filters.value.titleCont });

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const label = computed(() => t("labels.filters.fleets.titleFilter"));
</script>

<template>
  <form @submit.prevent="filter(form)">
    <FormInput
      v-model="form.titleCont"
      name="titleCont"
      :label="label"
      :placeholder="label"
      :no-label="true"
      :clearable="true"
    />
  </form>
</template>
