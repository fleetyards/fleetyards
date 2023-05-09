<template>
  <Btn
    v-if="extensionReady"
    :size="size"
    :variant="variant"
    :aria-label="t('actions.import')"
    :loading="loading"
    @click.native="openModal"
  >
    <i class="fal fa-sync" />
    <span>
      {{ t("actions.syncRsiHangar") }}
    </span>
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import type {
  Props as BtnProps,
  BtnVariants,
  BtnSizes,
} from "@/frontend/core/components/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/frontend/composables/useComlink";
import Store from "@/frontend/lib/Store";

interface Props extends BtnProps {
  variant?: BtnVariants;
  size?: BtnSizes;
}

withDefaults(defineProps<Props>(), {
  variant: "default",
  size: "default",
});

const { t } = useI18n();

const extensionReady = ref(false);

const loading = ref(false);

onMounted(() => {
  window.addEventListener("message", handleExtensionMessage);

  checkExtension();
});

onBeforeUnmount(() => {
  window.removeEventListener("message", handleExtensionMessage);
});

const handleExtensionMessage = (event: FleetyardsSyncEvent) => {
  if (event.data.direction === "fy-sync") {
    const message = JSON.parse(event.data.message);

    if (message.action === "health") {
      if (message.code === 200) {
        console.info("FY Extension: Ready");
        extensionReady.value = true;
      } else {
        console.info("FY Extension: Unavailable");
        extensionReady.value = false;
      }
    }
  }
};

watch(
  () => extensionReady.value,
  () => {
    Store.dispatch("hangar/updateExtensionReady", extensionReady.value);
  }
);

const checkExtension = () => {
  window.postMessage({ direction: "fy", message: '{ "action": "health" }' });
};

const comlink = useComlink();

const openModal = () => {
  comlink.$emit("open-modal", {
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
