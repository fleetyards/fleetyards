<template>
  <Btn
    v-if="!mobile"
    :size="size"
    :variant="variant"
    :aria-label="t('actions.import')"
    :loading="loading"
    @click="openModal"
  >
    <i class="fal fa-sync" />
    <span>
      {{ t("actions.syncRsiHangar") }}
    </span>
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import type {
  Props as BtnProps,
  BtnVariants,
  BtnSizes,
} from "@/shared/components/BaseBtn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useRouter, useRoute } from "vue-router";
import { useMobile } from "@/shared/composables/useMobile";
import { useHangarStore } from "@/frontend/stores/hangar";

interface Props extends BtnProps {
  variant?: BtnVariants;
  size?: BtnSizes;
}

withDefaults(defineProps<Props>(), {
  variant: "default",
  size: "default",
});

const { t } = useI18n();

const loading = ref(false);

const mobile = useMobile();

const router = useRouter();
const route = useRoute();

onMounted(() => {
  window.addEventListener("message", handleExtensionMessage);

  checkExtension();

  if (route.query.openSync) {
    router.replace({
      name: "hangar",
      query: { ...route.query, openSync: undefined },
    });

    openModal();
  }
});

onBeforeUnmount(() => {
  window.removeEventListener("message", handleExtensionMessage);
});

const hangarStore = useHangarStore();

const handleExtensionMessage = (event: FleetyardsSyncEvent) => {
  if (event.data.direction === "fy-sync") {
    const message = JSON.parse(event.data.message);

    if (message.action === "health") {
      if (message.code === 200) {
        console.info("FY Extension: Ready");
        hangarStore.extensionReady = true;
      } else {
        console.info("FY Extension: Unavailable");
        hangarStore.extensionReady = false;
      }
    }
  }
};

const checkExtension = () => {
  window.postMessage({ direction: "fy", message: '{ "action": "health" }' });
};

const comlink = useComlink();

const openModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/HangarSyncBtn/Modal/index.vue"),
    fixed: true,
  });
};
</script>

<script lang="ts">
export default {
  name: "HangarSyncBtn",
};
</script>
