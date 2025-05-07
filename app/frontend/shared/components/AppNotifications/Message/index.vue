<script lang="ts">
export default {
  name: "AppNotificationsMessage",
};
</script>

<script lang="ts" setup>
import { type AppNotification } from "@/shared/components/AppNotifications/types";
import { useNotificationsStore } from "@/shared/stores/notifications";
import ProgressBar from "@/shared/components/AppNotifications/ProgressBar/index.vue";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";

type Props = {
  message: AppNotification;
};

const props = defineProps<Props>();

const type = computed(() => {
  return props.message.type;
});

const messageClasses = computed(() => {
  return {
    [`app-notifications__message--${type.value}`]: true,
  };
});

const notificationsStore = useNotificationsStore();

const hideMessage = () => {
  notificationsStore.hideMessage(props.message.id);
};

const component = computed(() => {
  if (!props.message.component) {
    return;
  }

  return markRaw(defineAsyncComponent(props.message.component));
});

const componentProps = computed(() => {
  return props.message.componentProps;
});

onMounted(() => {
  if (props.message.timeout) {
    setTimeout(() => {
      notificationsStore.hideMessage(props.message.id);
    }, props.message.timeout + 150);
  }
});
</script>

<template>
  <div
    class="app-notifications__message"
    :class="messageClasses"
    @click="hideMessage"
  >
    <component :is="component" v-if="component" v-bind="componentProps" />
    <MessageBody v-else>
      {{ message.text }}
    </MessageBody>
    <ProgressBar :timeout="message.timeout" />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
