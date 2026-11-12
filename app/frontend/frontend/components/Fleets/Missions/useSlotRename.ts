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
  const saving = new Set<string>();
  let input: HTMLInputElement | null = null;

  // A function ref, as a string ref inside a v-for collects an array. Only a
  // mounted input is kept: the previous row's input can unmount after the
  // next one mounts and would otherwise clear it.
  const setRenameInput = (el: unknown) => {
    if (el) input = el as HTMLInputElement;
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

  // Enter is followed by a blur, so a save already on its way is not sent
  // again. The input stays open until the request settles, keeping what was
  // typed when it fails.
  const saveRename = async (slot: MissionSlot) => {
    if (renamingId.value !== slot.id || saving.has(slot.id)) return;

    const title = renameValue.value.trim();
    if (!title || title === slot.title) {
      cancelRename();
      return;
    }

    saving.add(slot.id);
    try {
      await lineup.updateSlot(slot.id, { title });
      if (renamingId.value === slot.id) cancelRename();
      onRenamed();
    } catch {
      displayAlert({ text: t("messages.fleets.missionSlot.update.failure") });
    } finally {
      saving.delete(slot.id);
    }
  };

  // Enter also picks an IME candidate, which must not save a half-typed name.
  const submitRename = (event: KeyboardEvent, slot: MissionSlot) => {
    if (event.isComposing) return;

    event.preventDefault();
    void saveRename(slot);
  };

  return {
    renamingId,
    renameValue,
    setRenameInput,
    startRename,
    cancelRename,
    saveRename,
    submitRename,
  };
};
