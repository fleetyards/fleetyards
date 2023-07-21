import axios from "axios";

export const useWebpCheck = () => {
  const supported = ref(true);

  onMounted(() => {
    check();
  });

  const check = async () => {
    if (typeof createImageBitmap === "undefined") {
      return false;
    }

    const webpData =
      "data:image/webp;base64,UklGRh4AAABXRUJQVlA4TBEAAAAvAAAAAAfQ//73v/+BiOh/AAA=";
    const response = await axios.get(webpData, { responseType: "blob" });

    supported.value = await createImageBitmap(response.data).then(
      () => true,
      () => false
    );

    return supported.value;
  };

  return {
    check,
    supported,
  };
};
