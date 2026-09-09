/*
 * Probing for WebGL costs a WebGL context. Browsers cap how many can exist at
 * once, so a probe that stays open spends a slot to find out whether a slot is
 * free -- and the renderer built right after it is the one that runs out.
 * `WEBGL_lose_context` is the only way to hand one back before GC.
 */
export const webglAvailable = (): boolean => {
  try {
    const canvas = document.createElement("canvas");
    const context = canvas.getContext("webgl2") ?? canvas.getContext("webgl");

    if (!context) {
      return false;
    }

    context.getExtension("WEBGL_lose_context")?.loseContext();

    return true;
  } catch {
    return false;
  }
};
