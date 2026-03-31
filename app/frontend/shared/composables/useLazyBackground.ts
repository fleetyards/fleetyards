interface UseLazyBackgroundOptions {
  rootMargin?: string;
  threshold?: number;
}

export const useLazyBackground = (
  target: Ref<HTMLElement | null>,
  src: Ref<string | undefined> | ComputedRef<string | undefined>,
  options: UseLazyBackgroundOptions = {},
) => {
  const { rootMargin = "200px", threshold = 0 } = options;

  const isLoaded = ref(false);

  let observer: IntersectionObserver | null = null;

  const loadImage = (el: HTMLElement, url: string) => {
    const img = new Image();
    img.onload = () => {
      el.style.backgroundImage = `url(${url})`;
      isLoaded.value = true;
    };
    img.onerror = () => {
      isLoaded.value = true;
    };
    img.src = url;
  };

  const setupObserver = () => {
    if (!target.value) return;

    observer?.disconnect();

    // eslint-disable-next-line compat/compat
    observer = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting && target.value) {
          observer?.disconnect();
          observer = null;

          const url = toValue(src);
          if (url) {
            loadImage(target.value, url);
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
    if (newSrc && isLoaded.value && target.value) {
      loadImage(target.value, newSrc);
    }
  });

  onUnmounted(() => {
    observer?.disconnect();
    observer = null;
  });

  return {
    isLoaded,
  };
};
