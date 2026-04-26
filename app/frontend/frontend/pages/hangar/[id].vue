<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { useShowVehicle } from "@/services/fyApi";

const route = useRoute();

const id = computed(() => route.params.id as string);

const { data: vehicle, ...asyncStatus } = useShowVehicle(id);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view v-if="vehicle" :vehicle="vehicle" />
    </template>
  </AsyncData>
</template>
