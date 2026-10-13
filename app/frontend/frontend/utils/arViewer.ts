export type ModelViewerElement = HTMLElement & {
  activateAR: () => Promise<void>;
  canActivateAR: boolean;
  updateComplete: Promise<boolean>;
};

// A cheap first guess, so a desktop never downloads the viewer: model-viewer
// itself makes the final call (`canActivateAR`), and it rules out more -- Firefox
// on Android, third-party browsers on iOS.
export const mayHaveAr = (
  userAgent: string = navigator.userAgent,
  anchor: HTMLAnchorElement = document.createElement("a"),
): boolean => !!anchor.relList?.supports?.("ar") || /android/i.test(userAgent);

// Quick Look, which only exists on iOS: the holo is converted to USDZ in the
// page for it, where Scene Viewer fetches the file itself.
export const usesQuickLook = (
  anchor: HTMLAnchorElement = document.createElement("a"),
): boolean => !!anchor.relList?.supports?.("ar");

// The standalone build carries its own three.js: the module build takes ours as
// a peer, and its supported range lags the version the holo viewer runs on.
const loadModelViewer = () =>
  import("@google/model-viewer/dist/model-viewer.min.js");

const nextTask = () => new Promise((resolve) => setTimeout(resolve));

// Scene Viewer has to be launched from the tap itself: model-viewer only
// settles on a mode after an update, and a launch that waits for a download
// loses the gesture, so the element is ready before the tap.
// `ar-scale="fixed"` keeps it at 1:1: the holo is exported in meters.
export const prepareAr = async (
  holoUrl: string,
): Promise<ModelViewerElement | undefined> => {
  await loadModelViewer();
  await customElements.whenDefined("model-viewer");

  const element = document.createElement("model-viewer") as ModelViewerElement;
  element.setAttribute("src", holoUrl);
  element.setAttribute("ar", "");
  element.setAttribute("ar-modes", "scene-viewer");
  element.setAttribute("ar-scale", "fixed");
  element.setAttribute("loading", "lazy");
  element.style.display = "none";
  document.body.appendChild(element);

  try {
    await element.updateComplete;
    await nextTask();
  } catch (error) {
    element.remove();
    throw error;
  }

  if (!element.canActivateAR) {
    element.remove();
    return undefined;
  }

  return element;
};

// Quick Look without model-viewer: on an iPhone its second three.js, its WebGL
// context, its model cache and its own pool of Draco workers outlived the first
// tap, and a second conversion on top of them did not survive. Quick Look needs
// no gesture, so the conversion may come first.
// `wanted` is asked once the conversion is done, so a page left meanwhile does
// not open Quick Look for a holo no longer on screen.
export const openQuickLook = async (
  holoUrl: string,
  wanted: () => boolean = () => true,
): Promise<void> => {
  const { holoToUsdz } = await import("@/frontend/utils/usdz");
  const usdz = await holoToUsdz(holoUrl);

  if (!wanted()) return;

  const url = URL.createObjectURL(usdz);

  const anchor = document.createElement("a");
  anchor.setAttribute("rel", "ar");
  anchor.setAttribute("download", "holo.usdz");
  // The holo is exported in meters: Quick Look places it at true size.
  anchor.setAttribute("href", `${url}#allowsContentScaling=0`);
  // Safari only hands a link to Quick Look when it wraps an image.
  anchor.appendChild(document.createElement("img"));
  anchor.style.display = "none";
  document.body.appendChild(anchor);

  anchor.click();
  // Released the way model-viewer does: Safari has taken the file on the click.
  URL.revokeObjectURL(url);
  setTimeout(() => anchor.remove());
};
