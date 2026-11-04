import { onErrorCaptured, onMounted, ref } from "vue";
import { webglAvailable } from "@/shared/utils/Webgl";

export const useWebglSupport = () => {
  const webglSupported = ref(true);

  // A canvas mounts before this does, so it may have failed already. A probe that
  // finds a context must not undo that: browsers cap how many can exist at once,
  // and a renderer can fail where the probe just succeeded.
  onMounted(() => {
    if (webglSupported.value && !webglAvailable()) {
      webglSupported.value = false;
    }
  });

  // THREE throws while constructing the renderer, which TresCanvas's `on-error`
  // never sees: it comes out through Vue's error handler instead.
  onErrorCaptured((error) => {
    if (!(error instanceof Error) || !error.message.includes("WebGL")) {
      return true;
    }

    webglSupported.value = false;

    return false;
  });

  return { webglSupported };
};
