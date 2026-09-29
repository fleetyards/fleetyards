export type ArMode = "quick-look" | "scene-viewer";

type ModelViewerElement = HTMLElement & {
  activateAR: () => Promise<void>;
  canActivateAR: boolean;
};

// Quick Look is announced by the browser itself; Scene Viewer is not detectable
// from a page, so any Android device is offered it and the phone decides.
export const arMode = (
  userAgent: string = navigator.userAgent,
  anchor: HTMLAnchorElement = document.createElement("a"),
): ArMode | undefined => {
  if (anchor.relList?.supports?.("ar")) {
    return "quick-look";
  }

  if (/android/i.test(userAgent)) {
    return "scene-viewer";
  }

  return undefined;
};

// The standalone build carries its own three.js: the module build takes ours as
// a peer, and its supported range lags the version the holo viewer runs on. It
// is only fetched once somebody asks for AR, so its weight is theirs alone.
const loadModelViewer = () =>
  import("@google/model-viewer/dist/model-viewer.min.js");

const whenLoaded = (element: HTMLElement) =>
  new Promise<void>((resolve, reject) => {
    element.addEventListener("load", () => resolve(), { once: true });
    element.addEventListener("error", () => reject(new Error("load")), {
      once: true,
    });
  });

// Quick Look needs a USDZ, which model-viewer builds from the loaded scene, so
// the holo is downloaded first. Scene Viewer fetches the file itself from the
// URL. `ar-scale="fixed"` keeps both at 1:1: the holo is exported in meters.
export const openInAr = async (holoUrl: string, mode: ArMode) => {
  await loadModelViewer();
  await customElements.whenDefined("model-viewer");

  const element = document.createElement("model-viewer") as ModelViewerElement;
  element.setAttribute("src", holoUrl);
  element.setAttribute("ar", "");
  element.setAttribute("ar-modes", mode);
  element.setAttribute("ar-scale", "fixed");
  element.setAttribute("loading", "eager");
  element.style.cssText =
    "position:fixed;width:1px;height:1px;opacity:0;pointer-events:none;";
  document.body.appendChild(element);

  try {
    if (mode === "quick-look") {
      await whenLoaded(element);
    }

    await element.activateAR();
  } finally {
    // Scene Viewer and Quick Look run outside the page once they are open.
    setTimeout(() => element.remove(), 60_000);
  }
};
