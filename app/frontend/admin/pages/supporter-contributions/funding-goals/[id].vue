<script lang="ts" setup>
import { useFundingGoal as useFundingGoalQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: fundingGoal, ...asyncStatus } = useFundingGoalQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :funding-goal="fundingGoal" />
    </template>
  </AsyncData>
</template>
