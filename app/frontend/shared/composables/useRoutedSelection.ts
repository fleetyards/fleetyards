type UseRoutedSelectionOptions = {
  key: string;
  mobile: MaybeRefOrGetter<boolean>;
};

/*
 * The open record of a list that shows it as a page of its own on a phone. On
 * a phone opening one is navigation, so it takes a history entry and the back
 * gesture closes it again; beside the list it is only a highlighted row, and
 * the URL stays out of it.
 */
export const useRoutedSelection = ({
  key,
  mobile,
}: UseRoutedSelectionOptions) => {
  const route = useRoute();
  const router = useRouter();

  const routed = computed(() => {
    const value = route.query[key];

    return typeof value === "string" ? value : undefined;
  });

  const selectedId = ref<string | undefined>(routed.value);

  const withKey = (id?: string) => ({ query: { ...route.query, [key]: id } });

  // Closing steps back only when the entry behind this one is the same list
  // without the record open - the one opening it pushed. A filter changed
  // while it was open, a reload or a shared link leaves something else
  // there, and stepping back would undo that instead; the key is replaced
  // away then.
  const behindIsTheList = () =>
    router.options.history.state.back ===
    router.resolve(withKey(undefined)).fullPath;

  const open = (id: string) => {
    selectedId.value = id;

    if (!toValue(mobile)) {
      if (routed.value) {
        void router.replace(withKey(undefined));
      }

      return;
    }

    if (routed.value === id) {
      return;
    }

    if (routed.value) {
      void router.replace(withKey(id));

      return;
    }

    void router.push(withKey(id));
  };

  const close = () => {
    selectedId.value = undefined;

    if (!routed.value) {
      return;
    }

    if (behindIsTheList()) {
      router.back();

      return;
    }

    void router.replace(withKey(undefined));
  };

  // The back and forward gestures, which change the route without asking.
  watch(routed, (id) => {
    if (id !== selectedId.value) {
      selectedId.value = id;
    }
  });

  return { selectedId, open, close };
};
