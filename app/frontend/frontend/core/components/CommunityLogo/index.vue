<template>
  <img v-lazy="logoUrl" alt="made-by-the-community" />
</template>

<script>
import logoUrl from "@/images/community-logo.png";

export default {
  name: "CommunityLogo",

  computed: {
    logoUrl() {
      return logoUrl;
    },
  },
};
</script>
