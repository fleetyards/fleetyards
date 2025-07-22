import { useMobileStore } from "@/shared/stores/mobile";
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
    mobileStore.mobile = document.documentElement.clientWidth < 992;
  };

  return mobile;
};
