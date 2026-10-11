/*
 * A phone hides a list's checkboxes until a held row asks for them, and the
 * list then stays in that mode for as long as something is picked. Off a
 * phone the checkboxes are always there, so there is no mode to be in.
 */
export const useSelectionMode = (
  selectedCount: MaybeRefOrGetter<number>,
  mobile: MaybeRefOrGetter<boolean>,
) => {
  const active = ref(false);

  const selecting = computed(() => toValue(mobile) && active.value);

  const start = () => {
    active.value = true;
  };

  // Unticking the last row, clearing, or an action spending the selection all
  // end it: an empty selection mode is a list with nothing to tap open.
  watch(
    () => toValue(selectedCount),
    (count) => {
      if (!count) {
        active.value = false;
      }
    },
  );

  watch(
    () => toValue(mobile),
    (isMobile) => {
      if (!isMobile) {
        active.value = false;
      }
    },
  );

  return { selecting, start };
};
