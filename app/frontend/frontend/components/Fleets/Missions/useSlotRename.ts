import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { type MissionSlot } from "@/services/fyApi";
import { type useLineupApi } from "@/frontend/components/Fleets/Missions/useLineupApi";

export const useSlotRename = (
  lineup: ReturnType<typeof useLineupApi>,
  onRenamed: () => void,
) => {
  const { t } = useI18n();
  const { displayAlert } = useAppNotifications();

  const renamingId = ref<string | null>(null);
  const renameValue = ref("");
  let input: HTMLInputElement | null = null;

  // A function ref, as a string ref inside a v-for collects an array.
  const setRenameInput = (el: unknown) => {
    input = el as HTMLInputElement | null;
  };

  const startRename = (slot: MissionSlot) => {
    renamingId.value = slot.id;
    renameValue.value = slot.title;
    void nextTick(() => {
      input?.focus();
      input?.select();
    });
  };

  const cancelRename = () => {
    renamingId.value = null;
    renameValue.value = "";
  };

  // Enter closes the input, which fires a blur after it; the id guard keeps
  // that second call from saving again.
  const saveRename = async (slot: MissionSlot) => {
    if (renamingId.value !== slot.id) return;

    const title = renameValue.value.trim();
    cancelRename();
    if (!title || title === slot.title) return;

    await lineup
      .updateSlot(slot.id, { title })
      .then(onRenamed)
      .catch(() =>
        displayAlert({
          text: t("messages.fleets.missionSlot.update.failure"),
        }),
      );
  };

  return {
    renamingId,
    renameValue,
    setRenameInput,
    startRename,
    cancelRename,
    saveRename,
  };
};
