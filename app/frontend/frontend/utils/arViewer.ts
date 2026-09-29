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

// The standalone build carries its own three.js: the module build takes ours as
// a peer, and its supported range lags the version the holo viewer runs on.
const loadModelViewer = () =>
  import("@google/model-viewer/dist/model-viewer.min.js");

const nextTask = () => new Promise((resolve) => setTimeout(resolve));

// Ready before the AR tap, because Scene Viewer and Quick Look have to be
// launched from the tap itself: model-viewer only settles on a mode after an
// update, and a launch that waits for a download loses the gesture. Prepared
// once the 3D view is open, so the holo is already in the browser's cache when
// Quick Look loads it to build its USDZ; Scene Viewer fetches it itself.
// `ar-scale="fixed"` keeps both at 1:1: the holo is exported in meters.
export const prepareAr = async (
  holoUrl: string,
): Promise<ModelViewerElement | undefined> => {
  await loadModelViewer();
  await customElements.whenDefined("model-viewer");

  const element = document.createElement("model-viewer") as ModelViewerElement;
  element.setAttribute("src", holoUrl);
  element.setAttribute("ar", "");
  element.setAttribute("ar-modes", "scene-viewer quick-look");
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
