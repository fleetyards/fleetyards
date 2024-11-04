<template>
  <img v-lazy="logoUrl" alt="made-by-the-community" />
</template>

<script lang="ts" setup>
import logoUrl from "@/images/community-logo.png";
</script>

<script lang="ts">
export default {
  name: "CommunityLogo",
};
</script>
