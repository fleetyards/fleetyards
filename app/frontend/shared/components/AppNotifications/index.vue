<script lang="ts">
export default {
  name: "AppNotifications",
};
</script>

<script lang="ts" setup>
import { useNotificationsStore } from "@/shared/stores/notifications";
import AppNotificationsMessage from "@/shared/components/AppNotifications/Message/index.vue";

const notificationsStore = useNotificationsStore();

const maxMessages = ref(5);

const visibleMessages = computed(() => {
  return notificationsStore.messages
    .filter((message) => message.visible)
    .slice(0, maxMessages.value);
});
</script>

<template>
  <div class="app-notifications">
    <TransitionGroup name="app-notifications-fade">
      <AppNotificationsMessage
        v-for="message in visibleMessages"
        :key="message.id"
        class="fade-list-item"
        :message="message"
      />
    </TransitionGroup>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
