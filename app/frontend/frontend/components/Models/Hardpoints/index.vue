<script lang="ts">
export default {
  name: "ModelHardpoints",
};
</script>

<script lang="ts" setup>
import Hardpoints from "@/frontend/components/Models/Hardpoints/new.vue";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

defineProps<Props>();
</script>

<template>
  <Hardpoints :model="model" />
</template>
