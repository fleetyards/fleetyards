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

  // Whether the entry carrying the key is one this page pushed. Closing steps
  // back over it then; one that came with the URL - a reload, a shared link -
  // has nothing of this list's behind it, so it is replaced instead.
  let pushed = false;

  const withKey = (id?: string) => ({ query: { ...route.query, [key]: id } });

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

    pushed = true;
    void router.push(withKey(id));
  };

  const close = () => {
    selectedId.value = undefined;

    if (!routed.value) {
      return;
    }

    if (pushed) {
      pushed = false;
      router.back();

      return;
    }

    void router.replace(withKey(undefined));
  };

  // The back and forward gestures, which change the route without asking.
  watch(routed, (id) => {
    if (id === selectedId.value) {
      return;
    }

    if (!id) {
      pushed = false;
    }

    selectedId.value = id;
  });

  return { selectedId, open, close };
};
