<script lang="ts">
export default {
  name: "AdminImagesPage",
};
</script>

<script lang="ts" setup>
import ImagesList from "@/admin/components/Images/List.vue";
</script>

<template>
  <ImagesList filterable />
</template>
