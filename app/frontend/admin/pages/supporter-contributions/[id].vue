<script lang="ts" setup>
import { useSupporterContribution as useSupporterContributionQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: supporterContribution, ...asyncStatus } =
  useSupporterContributionQuery(route.params.id as string);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :supporter-contribution="supporterContribution" />
    </template>
  </AsyncData>
</template>
