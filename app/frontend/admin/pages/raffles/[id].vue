<script lang="ts" setup>
import { useRaffle as useRaffleQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: raffle, ...asyncStatus } = useRaffleQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :raffle="raffle" />
    </template>
  </AsyncData>
</template>
