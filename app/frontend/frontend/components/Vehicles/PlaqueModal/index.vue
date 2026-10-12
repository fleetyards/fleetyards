<script lang="ts">
export default {
  name: "VehiclePlaqueModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type VehiclePublic } from "@/services/fyApi";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { plaqueShareUrl } from "@/frontend/components/Vehicles/Plaque/shareUrl";
import { usePublicHangarShare } from "@/frontend/composables/usePublicHangarShare";

type Props = {
  vehicle: VehiclePublic;
  // The hangar's owner, which the link names: the payload carries it only when
  // the owner shows it.
  username?: string;
};

const props = withDefaults(defineProps<Props>(), {
  username: undefined,
});

const { share } = usePublicHangarShare();

const shareUrl = computed(() =>
  props.username
    ? plaqueShareUrl(props.username, props.vehicle.id, share.value)
    : undefined,
);

// Copying from inside the modal needs a node inside it, or the clipboard gets
// nothing while reporting success.
const container = ref<HTMLElement>();

const { t } = useI18n();
</script>

<template>
  <Modal :title="t('headlines.vehiclePlaque.title')">
    <div ref="container">
      <VehiclePlaque :vehicle="vehicle" :captain="vehicle.username" />
    </div>

    <template v-if="shareUrl" #footer>
      <ShareBtn
        :url="shareUrl"
        :title="t('headlines.vehiclePlaque.title')"
        :container="container"
        data-test="vehicle-plaque-share"
      />
    </template>
  </Modal>
</template>
