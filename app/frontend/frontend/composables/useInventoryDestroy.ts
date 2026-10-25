import { useQueryClient } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";

type Options = {
  inventory: () => { id?: string | null } | undefined;
  destroy: () => Promise<unknown>;
  listKey: () => readonly unknown[];
  onDeleted: () => void;
};

/*
 * Deleting a hangar or fleet inventory, wherever it is offered. A refusal
 * names its reason -- an open contract still delivering into it -- rather than
 * only saying it failed.
 */
export const useInventoryDestroy = ({
  inventory,
  destroy,
  listKey,
  onDeleted,
}: Options) => {
  const { t } = useI18n();
  const { displaySuccess, displayAlert } = useAppNotifications();
  const queryClient = useQueryClient();

  const deleting = ref(false);

  // The list the reader lands on next draws from the cache before its refetch
  // answers, so the deleted inventory is taken out of it here. Matched by id:
  // the list key is also a prefix of every item list, whose rows have slugs of
  // their own.
  const dropFromLists = (id: string) => {
    queryClient.setQueriesData<{ items?: { id?: string | null }[] }>(
      { queryKey: listKey() },
      (data) =>
        data?.items
          ? { ...data, items: data.items.filter((item) => item.id !== id) }
          : data,
    );
  };

  const destroyInventory = async () => {
    const id = inventory()?.id;

    if (!id) return;

    deleting.value = true;

    await destroy()
      .then(() => {
        dropFromLists(id);
        displaySuccess({
          text: t("messages.logistics.inventory.destroy.success"),
        });
        onDeleted();
      })
      .catch((error: unknown) => {
        displayAlert({
          text:
            firstErrorMessageFrom(error) ??
            t("messages.logistics.inventory.destroy.failure"),
        });
      })
      .finally(() => {
        deleting.value = false;
      });
  };

  return { deleting, destroyInventory };
};
