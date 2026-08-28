type Identifiable = { id: string };

// Two selections in one: the ids of the rows the reader ticked, and a flag
// meaning "everything this filter matches". The second one never becomes a list
// of ids - the server resolves it against the same filter - so it survives
// paging and costs nothing on a filter with thousands of hits.
export const useBulkSelection = <T extends Identifiable, Q>(
  records: MaybeRefOrGetter<T[]>,
  query: MaybeRefOrGetter<Q>,
  totalCount: MaybeRefOrGetter<number | undefined>,
) => {
  const selectedIds = ref<string[]>([]);
  const allMatchingSelected = ref(false);

  const pageIds = computed(() => toValue(records).map((record) => record.id));

  const matchingCount = computed(
    () => toValue(totalCount) ?? pageIds.value.length,
  );

  // A row that left the page - deleted, filtered away, or simply on the page
  // before this one - takes its tick with it. Without this an action could
  // reach records the reader can no longer see.
  watch(pageIds, (ids) => {
    selectedIds.value = selectedIds.value.filter((id) => ids.includes(id));
  });

  // "All 143 matching" is a statement about the filter, so a different filter
  // revokes it. Paging leaves it alone: the same filter still matches.
  //
  // Serialised rather than watched by reference: the caller builds its query
  // from a computed, so turning the page hands over a new object holding the
  // same filter, and identity alone would drop the selection for it.
  watch(
    () => JSON.stringify(toValue(query)),
    () => {
      allMatchingSelected.value = false;
    },
  );

  const selectedCount = computed(() =>
    allMatchingSelected.value ? matchingCount.value : selectedIds.value.length,
  );

  const pageSelected = computed(
    () =>
      pageIds.value.length > 0 &&
      (allMatchingSelected.value ||
        pageIds.value.every((id) => selectedIds.value.includes(id))),
  );

  const pagePartiallySelected = computed(
    () => !pageSelected.value && selectedIds.value.length > 0,
  );

  // Only worth offering while there is more behind the filter than on the page.
  const canSelectAllMatching = computed(
    () =>
      !allMatchingSelected.value &&
      pageSelected.value &&
      matchingCount.value > pageIds.value.length,
  );

  const clear = () => {
    selectedIds.value = [];
    allMatchingSelected.value = false;
  };

  const toggle = (id: string) => {
    // Unticking one row is a narrower statement than "everything matching", so
    // the selection drops back to the page it can actually show.
    if (allMatchingSelected.value) {
      allMatchingSelected.value = false;
      selectedIds.value = pageIds.value.filter((pageId) => pageId !== id);

      return;
    }

    selectedIds.value = selectedIds.value.includes(id)
      ? selectedIds.value.filter((selected) => selected !== id)
      : [...selectedIds.value, id];
  };

  const togglePage = (selected: boolean) => {
    allMatchingSelected.value = false;
    selectedIds.value = selected ? [...pageIds.value] : [];
  };

  const selectAllMatching = () => {
    allMatchingSelected.value = true;
  };

  const payload = computed(() =>
    allMatchingSelected.value
      ? { all: true, q: toValue(query) }
      : { ids: [...selectedIds.value] },
  );

  return {
    selectedIds,
    allMatchingSelected,
    selectedCount,
    matchingCount,
    pageSelected,
    pagePartiallySelected,
    canSelectAllMatching,
    toggle,
    togglePage,
    selectAllMatching,
    clear,
    payload,
  };
};
