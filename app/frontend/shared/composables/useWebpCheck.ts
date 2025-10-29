import axios from "axios";
import { useWebpStore } from "@/shared/stores/webp";

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
    if (typeof createImageBitmap === "undefined") {
      webpStore.supported = false;
    }

    const webpData =
      "data:image/webp;base64,UklGRh4AAABXRUJQVlA4TBEAAAAvAAAAAAfQ//73v/+BiOh/AAA=";
    const response = await axios.get(webpData, { responseType: "blob" });

    webpStore.supported = await createImageBitmap(response.data).then(
      () => true,
      () => false,
    );

    return webpStore.supported;
  };

  return {
    check,
    supported,
  };
};
