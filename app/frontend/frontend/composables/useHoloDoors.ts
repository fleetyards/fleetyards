import { type MaybeRefOrGetter, toValue } from "vue";

/**
 * Which of a holo's doors stand open: all or none as the caller's switch says,
 * and each one turned the other way by a click until the switch moves again.
 */
export const useHoloDoors = (
  doors: MaybeRefOrGetter<{ id: string }[]>,
  allOpen: MaybeRefOrGetter<boolean>,
) => {
  const open = ref(new Set<string>());

  const reset = () => {
    open.value = new Set(
      toValue(allOpen) ? toValue(doors).map((door) => door.id) : [],
    );
  };

  watch(
    () => [
      toValue(allOpen),
      toValue(doors)
        .map((door) => door.id)
        .join(),
    ],
    reset,
    { immediate: true },
  );

  const toggleDoor = (id: string) => {
    const next = new Set(open.value);
    if (!next.delete(id)) next.add(id);
    open.value = next;
  };

  const isOpen = (id: string) => open.value.has(id);

  const openDoors = computed(() => [...open.value]);

  return { openDoors, isOpen, toggleDoor };
};
