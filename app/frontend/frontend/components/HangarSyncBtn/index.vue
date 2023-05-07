<template>
  <Btn
    v-if="extensionReady"
    :size="size"
    :variant="variant"
    :aria-label="t('actions.import')"
    :loading="loading"
    @click.native="startSync"
  >
    <i class="fal fa-sync" />
    <span>
      {{ t("actions.syncRsiHangar") }}
    </span>
  </Btn>
</template>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Btn from "@/frontend/core/components/Btn/index.vue";
import type {
  Props as BtnProps,
  BtnVariants,
  BtnSizes,
} from "@/frontend/core/components/Btn/index.vue";
import {
  displayAlert,
  displaySuccess,
  displayInfo,
  displayConfirm,
  displayWarning,
} from "@/frontend/lib/Noty";
import { useI18n } from "@/frontend/composables/useI18n";
import { useHangarStore } from "@/frontend/stores/Hangar";
import vehiclesCollection from "@/frontend/api/collections/Vehicles";
import type { VehiclesCollection } from "@/frontend/api/collections/Vehicles";

interface SyncExtensionEvent extends Event {
  data: {
    direction: "fy-sync" | "fy";
    message: string;
  };
}

interface Props extends BtnProps {
  variant: BtnVariants;
  size: BtnSizes;
}

withDefaults(defineProps<Props>(), {
  variant: "default",
  size: "default",
});

const collection: VehiclesCollection = vehiclesCollection;

const { t } = useI18n();

const hangarStore = useHangarStore();

const { extensionReady } = storeToRefs(hangarStore);

const loading = ref(false);

const currentPage = ref(1);

const lastPageReached = ref(false);

const pledges = ref<TRSIHangarItem[]>([]);

onMounted(() => {
  window.addEventListener("message", handleExtensionMessage);

  checkExtension();
});

onBeforeUnmount(() => {
  window.removeEventListener("message", handleExtensionMessage);
});

const handleExtensionMessage = (event: SyncExtensionEvent) => {
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

    if (!hangarStore.extensionReady) {
      return;
    }

    if (message.action === "sync") {
      if (message.code === 200) {
        parseRawPage(message.payload);
      } else {
        loading.value = false;
        displayAlert({ text: t("messages.syncExtension.failure") });
      }
    }

    if (message.action === "identify") {
      if (message.code !== 200 || !message.payload?.handle) {
        console.info("FY Extension: No RSI Session found");
        displayWarning({ text: t("messages.syncExtension.notLoggedIn") });
        hangarStore.extensionReady = false;
      }
    }
  }
};

watch(
  () => hangarStore.extensionReady,
  () => {
    if (hangarStore.extensionReady) {
      window.postMessage({
        direction: "fy",
        message: '{ "action": "identify" }',
      });
    }
  }
);

const checkExtension = () => {
  window.postMessage({ direction: "fy", message: '{ "action": "health" }' });
};

const parseRawPage = (rawPage: string) => {
  const htmlDoc = new DOMParser().parseFromString(rawPage, "text/html");

  checkForLastPage(htmlDoc);

  if (lastPageReached.value) {
    finishSync();
    return;
  }

  const pledgeList = htmlDoc.getElementsByClassName("list-items")[0];

  if (!pledgeList) {
    loading.value = false;
    displayAlert({ text: t("messages.syncExtension.failure") });
    return;
  }

  const entries = pledgeList.getElementsByTagName("li");

  Array.from(entries).forEach((entry) => {
    const id = (
      entry.getElementsByClassName("js-pledge-id")[0] as HTMLInputElement
    )?.value;

    const items = entry.getElementsByClassName("item");

    Array.from(items).forEach((item) => {
      const pledge = parseItem(id, item);
      if (pledge) {
        pledges.value.push(pledge);
      }
    });
  });

  currentPage.value += 1;

  window.postMessage({
    direction: "fy",
    message: `{ "action": "sync", "page": ${currentPage.value} }`,
  });
};

const parseItem = (id: string, item: Element): TRSIHangarItem | undefined => {
  const kind = item.getElementsByClassName("kind")[0]?.textContent;

  if (!kind || !["Ship", "Component"].includes(kind)) {
    return undefined;
  }

  return {
    id,
    name: item.getElementsByClassName("title")[0].textContent || "",
    customName:
      item.getElementsByClassName("custom-name-text")[0]?.textContent ||
      undefined,
    type: kind === "Ship" ? "ship" : "component",
  };
};

const checkForLastPage = (htmlDoc: Document) => {
  const emptyList = htmlDoc.getElementsByClassName("empty-list")[0];
  const empyList = htmlDoc.getElementsByClassName("empy-list")[0];

  if (emptyList || empyList) {
    currentPage.value = 0;
    lastPageReached.value = true;
  }
};

const startSync = () => {
  loading.value = true;
  pledges.value = [];
  currentPage.value = 1;
  lastPageReached.value = false;

  window.postMessage({
    direction: "fy",
    message: `{ "action": "sync", "page": ${currentPage.value} }`,
  });

  displayInfo({ text: t("messages.syncExtension.started") });
};

const finishSync = async () => {
  const response = await collection.syncRsiHangar(pledges.value);
  loading.value = false;
  displaySuccess({ text: t("messages.syncExtension.success") });
  console.log(pledges.value, response);
};
</script>

<script lang="ts">
export default {
  name: "HangarSyncBtn",
};
</script>
