<script lang="ts">
export default {
  name: "DestroyedFleetsFilterForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { type DestroyedFleetQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

const prefillFormValues = () => {
  return {
    nameOrFidCont: filters.value.nameOrFidCont,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, filters } = useFilters<DestroyedFleetQuery>({
  updateCallback: setupForm,
});

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<DestroyedFleetQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport to="#header-left">
      <FormInput
        v-model="form.nameOrFidCont"
        name="search"
        translation-key="filters.destroyedFleets.nameOrFid"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>
  </form>
</template>
