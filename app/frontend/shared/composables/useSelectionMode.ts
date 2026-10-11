/*
 * A phone hides a list's checkboxes until a held row picks something, and
 * the list is in selection mode for exactly as long as something is picked.
 * Derived rather than switched on and off, so every part of a list - its
 * table, its toolbar, its header - agrees, a rotation across the breakpoint
 * included. Off a phone the checkboxes are always there, so there is no mode.
 */
export const useSelectionMode = (
  selectedCount: MaybeRefOrGetter<number>,
  mobile: MaybeRefOrGetter<boolean>,
) => {
  const selecting = computed(
    () => toValue(mobile) && toValue(selectedCount) > 0,
  );

  return { selecting };
};
