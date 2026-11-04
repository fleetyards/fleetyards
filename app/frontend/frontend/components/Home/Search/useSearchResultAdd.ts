import { catalogueSelection } from "@/frontend/components/Logistics/selection";
import { type ItemPickerEntry } from "@/frontend/components/Logistics/types";
import { useSessionStore } from "@/frontend/stores/session";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import {
  blueprint,
  commodity,
  component,
  equipmentItem,
  model,
  type SearchResult,
} from "@/services/fyApi";

const INVENTORY_TYPES = ["Component", "Equipment", "Commodity"];
const HANGAR_TYPES = ["Model", "Blueprint"];

// `unavailable`: the record cannot be added, which only its full record tells.
export type SearchResultAddOutcome = "opened" | "unavailable" | "failed";

export const useSearchResultAdd = () => {
  const { t } = useI18n();
  const comlink = useComlink();
  const { displayAlert } = useAppNotifications();
  const sessionStore = useSessionStore();

  const canAdd = (result: SearchResult) =>
    sessionStore.isAuthenticated &&
    [...HANGAR_TYPES, ...INVENTORY_TYPES].includes(result.type);

  const openInventoryModal = (entry: ItemPickerEntry) => {
    if (entry.record.retired) return "unavailable";

    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Logistics/InventoryItemModal/index.vue"),
      props: { item: catalogueSelection(entry) },
    });

    return "opened";
  };

  const openModal = async ({
    slug,
    type,
  }: SearchResult): Promise<SearchResultAddOutcome> => {
    if (type === "Component") {
      return openInventoryModal({ type, record: await component(slug) });
    }
    if (type === "Equipment") {
      return openInventoryModal({ type, record: await equipmentItem(slug) });
    }
    if (type === "Commodity") {
      return openInventoryModal({ type, record: await commodity(slug) });
    }
    if (type === "Blueprint") {
      comlink.emit("open-modal", {
        component: () =>
          import("@/frontend/components/Blueprints/AddToHangar/Modal/index.vue"),
        props: { blueprint: await blueprint(slug) },
      });

      return "opened";
    }

    const record = await model(slug);
    if (!record.playerOwnable) return "unavailable";

    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Models/AddToHangar/Modal/index.vue"),
      props: { model: record },
    });

    return "opened";
  };

  const add = async (result: SearchResult): Promise<SearchResultAddOutcome> => {
    try {
      return await openModal(result);
    } catch {
      displayAlert({ text: t("messages.error.default") });

      return "failed";
    }
  };

  return { canAdd, add };
};
