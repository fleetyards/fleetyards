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
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import type { RouteLocationRaw } from "vue-router";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  inline?: boolean;
  to?: RouteLocationRaw;
  href?: string;
  type?: "button" | "submit";
  loading?: boolean;
  spinner?: boolean | SpinnerAlignment;
  exact?: boolean;
  block?: boolean;
  mobileBlock?: boolean;
  textInline?: boolean;
  active?: boolean;
  disabled?: boolean;
  routeActiveClass?: string;
  inGroup?: boolean;
};

withDefaults(defineProps<Props>(), {
  variant: BtnVariantsEnum.DEFAULT,
  size: BtnSizesEnum.DEFAULT,
  inline: false,
  to: undefined,
  href: undefined,
  type: "button",
  loading: false,
  spinner: false,
  exact: false,
  block: false,
  mobileBlock: false,
  textInline: false,
  active: false,
  disabled: false,
  routeActiveClass: undefined,
  inGroup: false,
});

const { t } = useI18n();

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
    <i class="fal fa-sync" />
    <span>
      {{ t("actions.syncRsiHangar") }}
    </span>
  </Btn>
</template>
