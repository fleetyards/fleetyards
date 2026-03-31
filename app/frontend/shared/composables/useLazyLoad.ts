type LazyLoadState = "idle" | "loading" | "loaded" | "error";

interface UseLazyLoadOptions {
  rootMargin?: string;
  threshold?: number;
}

export const useLazyLoad = (
  target: Ref<HTMLElement | null>,
  src: Ref<string | undefined> | ComputedRef<string | undefined>,
  options: UseLazyLoadOptions = {},
) => {
  const { rootMargin = "200px", threshold = 0 } = options;

  const state = ref<LazyLoadState>("idle");
  const loadedSrc = ref<string>();

  const isLoading = computed(() => state.value === "loading");
  const isLoaded = computed(() => state.value === "loaded");
  const hasError = computed(() => state.value === "error");

  const loadImage = (url: string) => {
    state.value = "loading";

    const img = new Image();
    img.onload = () => {
      loadedSrc.value = url;
      state.value = "loaded";
    };
    img.onerror = () => {
      state.value = "error";
    };
    img.src = url;
  };

  let observer: IntersectionObserver | null = null;

  const setupObserver = () => {
    if (!target.value) return;

    observer?.disconnect();

    // eslint-disable-next-line compat/compat
    observer = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting) {
          observer?.disconnect();
          observer = null;

          const url = toValue(src);
          if (url) {
            loadImage(url);
          }
        }
      },
      { rootMargin, threshold },
    );

    observer.observe(target.value);
  };

  watch(target, (el) => {
    if (el) {
      setupObserver();
    }
  });

  watch(src, (newSrc) => {
    if (newSrc && state.value === "loaded") {
      loadImage(newSrc);
    }
  });

  onUnmounted(() => {
    observer?.disconnect();
    observer = null;
  });

  return {
    state,
    loadedSrc,
    isLoading,
    isLoaded,
    hasError,
  };
};
