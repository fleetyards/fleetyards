import type PhotoSwipe from "photoswipe";
import type { SlideData } from "photoswipe";

type Translate = (key: string) => string;

// pswp's own chrome ships hardcoded English for its titles, which are both the
// tooltip and the accessible name of every button it draws.
export const photoSwipeTitles = (t: Translate) => ({
  closeTitle: t("actions.close"),
  zoomTitle: t("actions.zoom"),
  arrowPrevTitle: t("actions.previous"),
  arrowNextTitle: t("actions.next"),
  errorMsg: t("errors.imageNotLoaded"),
});

// A `download` attribute is ignored on another origin's file, and a plain link
// would navigate away from the page, so the file is fetched and saved from
// memory. A host that refuses the fetch still gets its image shown, in a tab of
// its own.
export const downloadImage = async (url: string, name: string) => {
  try {
    const response = await fetch(url);
    if (!response.ok) throw new Error(response.statusText);

    const objectUrl = URL.createObjectURL(await response.blob());
    const extension =
      new URL(url, window.location.href).pathname.match(/\.\w+$/)?.[0] || "";

    const link = document.createElement("a");
    link.href = objectUrl;
    link.download = `${name}${extension}`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    // Firefox and Safari start the download after `click` returns; revoked
    // straight away, the URL is gone before they read it.
    setTimeout(() => URL.revokeObjectURL(objectUrl), 0);
  } catch {
    window.open(url, "_blank", "noopener");
  }
};

// At 9, after pswp's own preloader at 7 and the gallery's copy button at 8.
export const registerDownloadButton = (
  pswp: PhotoSwipe,
  t: Translate,
  nameFor: (slide: SlideData) => string,
) => {
  pswp.ui?.registerElement({
    name: "download-button",
    order: 9,
    isButton: true,
    tagName: "button",
    title: t("actions.download"),
    html: '<i class="fa fa-download"></i>',
    onClick: () => {
      const slide = pswp.currSlide?.data;

      if (slide?.src) {
        void downloadImage(slide.src, nameFor(slide));
      }
    },
  });
};
