<script lang="ts">
export default {
  name: "ModelsAddToHangarNotification",
};
</script>

<script lang="ts" setup>
import { type Vehicle } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const model = computed(() => props.vehicle.model);

const image = computed(() => {
  if (model.value.media.storeImage) {
    return model.value.media.storeImage.medium;
  }
});

const alt = computed(() => model.value.name);

const title = computed(() => model.value.name);

const to = computed(() => {
  if (props.vehicle.wanted) {
    return {
      name: "hangar-wishlist",
    };
  }

  return {
    name: "hangar",
  };
});

const text = computed(() => {
  if (props.vehicle.wanted) {
    return t("messages.vehicle.add.success", {
      model: model.value.name,
    });
  }

  return t("messages.vehicle.addToWishlist.success", {
    model: model.value.name,
  });
});

const linkLabel = computed(() => {
  if (props.vehicle.wanted) {
    return t("labels.wishlist");
  }

  return t("labels.hangar");
});
</script>

<template>
  <div class="models-add-to-hangar-notification">
    <MessageBody>
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span v-html="text" />
      <router-link :to="to" class="models-add-to-hangar-notification__link">
        {{ linkLabel }}
      </router-link>
    </MessageBody>
    <img v-lazy="image" :alt="alt" :title="title || alt" />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
