<script lang="ts">
export default {
  name: "VisualTestsNotificationImageDemo",
};
</script>

<script lang="ts" setup>
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";

type Props = {
  title: string;
  body: string;
  image: string;
};

defineProps<Props>();
</script>

<template>
  <MessageBody>
    <b>{{ title }}</b>
    <br />
    {{ body }}
  </MessageBody>
  <img :src="image" :alt="title" />
</template>
