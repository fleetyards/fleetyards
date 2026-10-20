<script lang="ts" setup>
import { useGameEvent as useGameEventQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: gameEvent, ...asyncStatus } = useGameEventQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :game-event="gameEvent" />
    </template>
  </AsyncData>
</template>
