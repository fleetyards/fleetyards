import { webglAvailable } from "@/shared/utils/Webgl";

export const useWebglSupport = () => {
  // Probed before any canvas exists: a probe alongside a live canvas spends a
  // context it could cost that canvas, as browsers cap how many can exist.
  const webglSupported = ref(webglAvailable());

  // THREE throws while constructing the renderer, which TresCanvas's `on-error`
  // never sees: it comes out through Vue's error handler instead, even where the
  // probe found a context a moment earlier.
  onErrorCaptured((error) => {
    if (!(error instanceof Error) || !error.message.includes("WebGL")) {
      return true;
    }

    webglSupported.value = false;

    return false;
  });

  return { webglSupported };
};
