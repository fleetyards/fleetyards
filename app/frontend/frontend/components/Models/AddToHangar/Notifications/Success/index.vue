<script lang="ts">
export default {
  name: "ModelsAddToHangarNotificationSuccess",
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
    return model.value.media.storeImage.mediumUrl;
  }

  return undefined;
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

const linkLabel = computed(() => {
  if (props.vehicle.wanted) {
    return t("labels.wishlist");
  }

  return t("labels.hangar");
});

const paragraph2 = computed(() => {
  if (props.vehicle.wanted) {
    return t("messages.vehicle.addToWishlist.success.paragraph2");
  }

  return t("messages.vehicle.add.success.paragraph2");
});
</script>

<template>
  <MessageBody>
    {{ t("messages.vehicle.add.success.paragraph1") }}
    <b>{{ model.name }}</b>
    {{ paragraph2 }}
    <router-link :to="to" class="models-add-to-hangar-notification__link">
      {{ linkLabel }}
    </router-link>
  </MessageBody>
  <img v-lazy="image" :alt="alt" :title="title || alt" />
</template>
