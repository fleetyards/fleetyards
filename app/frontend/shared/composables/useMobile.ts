import { isMobileWidth, useMobileStore } from "@/shared/stores/mobile";
import { storeToRefs } from "pinia";

export const useMobile = () => {
  const mobileStore = useMobileStore();

  const { mobile } = storeToRefs(mobileStore);

  onMounted(() => {
    checkMobile();

    window.addEventListener("resize", checkMobile);
  });

  onUnmounted(() => {
    window.removeEventListener("resize", checkMobile);
  });

  const checkMobile = () => {
    mobileStore.mobile = isMobileWidth();
  };

  return mobile;
};
