<script lang="ts">
export default {
  name: "CommunityLogo",
};
</script>

<script lang="ts" setup>
import logoUrl from "@/images/community-logo.png";
</script>

<template>
  <img v-lazy="logoUrl" alt="made-by-the-community" />
</template>
