<script lang="ts">
export default {
  name: "HangarSyncBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import { useHangarStore } from "@/frontend/stores/hangar";
import type { FleetyardsSyncEvent } from "@/frontend/lib/FleetyardsSyncHandler";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

// Only what the wrapper forwards. Anything else a caller sets falls through to
// the Btn below on its own.
type Props = {
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  loading?: boolean;
};

withDefaults(defineProps<Props>(), {
  variant: undefined,
  size: undefined,
  loading: false,
});

const { t } = useI18n();

const mobile = useMobile();

const router = useRouter();
const route = useRoute();

onMounted(async () => {
  window.addEventListener("message", handleExtensionMessage);

  checkExtension();

  if (route.query.openSync) {
    await router.replace({
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
  checkExtension();

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/SyncBtn/Modal/index.vue"),
    fixed: true,
  });
};
</script>

<template>
  <Btn
    v-if="!mobile"
    :size="size"
    :variant="variant"
    :aria-label="t('actions.import')"
    :loading="loading"
    @click="openModal"
  >
    <i class="fa-light fa-sync" />
    <span>
      {{ t("actions.syncRsiHangar") }}
    </span>
  </Btn>
</template>
