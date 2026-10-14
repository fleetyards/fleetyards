<script lang="ts">
export default {
  name: "VehicleEditModalGroups",
};
</script>

<script lang="ts" setup>
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { useHangarGroups as useHangarGroupsQuery } from "@/services/fyApi";

const { data: hangarGroups } = useHangarGroupsQuery();
</script>

<template>
  <div class="row">
    <div v-for="group in hangarGroups" :key="group.id" class="col-12 col-md-6">
      <FormCheckbox
        :checkbox-value="group.id"
        name="hangarGroupIds"
        :label="group.name"
      />
    </div>
  </div>
</template>
