<script lang="ts">
export default {
  name: "HomeSearchResultAction",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { catalogueSelection } from "@/frontend/components/Logistics/selection";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useSessionStore } from "@/frontend/stores/session";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import {
  blueprint,
  commodity,
  component,
  equipmentItem,
  model,
  type SearchResult,
} from "@/services/fyApi";

type Props = {
  result: SearchResult;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  // A modal took over from the search.
  opened: [];
  // The record cannot be added, which only its full record tells.
  unavailable: [];
}>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();
const sessionStore = useSessionStore();
const hangarStore = useHangarStore();
const wishlistStore = useWishlistStore();

const INVENTORY_TYPES = ["Component", "Equipment", "Commodity"];

const addsToHangar = computed(() =>
  ["Model", "Blueprint"].includes(props.result.type),
);

const visible = computed(
  () =>
    sessionStore.isAuthenticated &&
    (addsToHangar.value || INVENTORY_TYPES.includes(props.result.type)),
);

const label = computed(() => {
  if (props.result.type === "Blueprint") {
    return t("actions.blueprint.addToAssets");
  }

  return addsToHangar.value
    ? t("actions.addToHangar")
    : t("actions.logistics.addToInventory");
});

// Only ships can say so up front: both lists are kept in the session, while a
// blueprint's marks arrive with its full record.
const marked = computed(
  () =>
    props.result.type === "Model" &&
    [...(hangarStore.ships || []), ...(wishlistStore.ships || [])].includes(
      props.result.slug,
    ),
);

const openInventoryModal = (
  entry: Parameters<typeof catalogueSelection>[0],
) => {
  if (entry.record.retired) {
    emit("unavailable");
    return;
  }

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/InventoryItemModal/index.vue"),
    props: { item: catalogueSelection(entry) },
  });
  emit("opened");
};

const openModal = async () => {
  const { slug, type } = props.result;

  if (type === "Component") {
    openInventoryModal({ type, record: await component(slug) });
  } else if (type === "Equipment") {
    openInventoryModal({ type, record: await equipmentItem(slug) });
  } else if (type === "Commodity") {
    openInventoryModal({ type, record: await commodity(slug) });
  } else if (type === "Blueprint") {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Blueprints/AddToHangar/Modal/index.vue"),
      props: { blueprint: await blueprint(slug) },
    });
    emit("opened");
  } else {
    const record = await model(slug);

    if (!record.playerOwnable) {
      emit("unavailable");
      return;
    }

    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Models/AddToHangar/Modal/index.vue"),
      props: { model: record },
    });
    emit("opened");
  }
};

const loading = ref(false);

const open = async () => {
  loading.value = true;

  try {
    await openModal();
  } catch {
    displayAlert({ text: t("messages.error.default") });
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <!-- A press on the row opens the item, so this one must not reach it. -->
  <span v-if="visible" @mousedown.stop>
    <Btn
      v-tooltip.bottom="label"
      :variant="BtnVariantsEnum.BARE"
      :size="BtnSizesEnum.SM"
      :loading="loading"
      :aria-label="label"
      data-test="home-search-action"
      @click.stop.prevent="open"
    >
      <i
        v-if="!addsToHangar"
        class="fa-duotone fa-box-open"
        aria-hidden="true"
      />
      <i v-else-if="marked" class="fa fa-bookmark" aria-hidden="true" />
      <i v-else class="fa-light fa-bookmark" aria-hidden="true" />
    </Btn>
  </span>
</template>
