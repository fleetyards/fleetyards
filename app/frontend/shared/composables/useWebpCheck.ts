import { useWebpStore } from "@/shared/stores/webp";

const WEBP_PIXEL =
  "data:image/webp;base64,UklGRh4AAABXRUJQVlA4TBEAAAAvAAAAAAfQ//73v/+BiOh/AAA=";

// Decoded by an image element rather than fetched: some browsers refuse a
// `data:` address over XHR, and older ones lack `createImageBitmap`.
const decodesWebp = () =>
  new Promise<boolean>((resolve) => {
    const image = new Image();
    image.onload = () => resolve(image.width > 0 && image.height > 0);
    image.onerror = () => resolve(false);
    image.src = WEBP_PIXEL;
  });

export const useWebpCheck = (write: boolean = false) => {
  const webpStore = useWebpStore();

  onMounted(async () => {
    if (write) {
      await check();
    }
  });

  const supported = computed(() => {
    return webpStore.supported;
  });

  const check = async () => {
    webpStore.supported = await decodesWebp();

    return webpStore.supported;
  };

  return {
    check,
    supported,
  };
};
