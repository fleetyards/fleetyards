import { useI18n } from "@/shared/composables/useI18n";

// One image full size, for an image with no stored dimensions: PhotoSwipe needs
// them up front, so they are read off the already loaded thumbnail, which is
// the same file.
export const useImageViewer = () => {
  const { t } = useI18n();

  // A `download` attribute is ignored on another origin's file, and a plain
  // link would navigate away from the page, so the file is fetched and saved
  // from memory. A host that refuses the fetch still gets its image shown,
  // in a tab of its own.
  const download = async (url: string, name: string) => {
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error(response.statusText);

      const objectUrl = URL.createObjectURL(await response.blob());
      const extension = new URL(url).pathname.match(/\.\w+$/)?.[0] || "";

      const link = document.createElement("a");
      link.href = objectUrl;
      link.download = `${name}${extension}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      URL.revokeObjectURL(objectUrl);
    } catch {
      window.open(url, "_blank", "noopener");
    }
  };

  const openImage = async (image: HTMLImageElement, alt: string) => {
    if (!image.naturalWidth) {
      return;
    }

    const { default: PhotoSwipe } = await import("photoswipe");

    const pswp = new PhotoSwipe({
      dataSource: [
        {
          src: image.currentSrc || image.src,
          width: image.naturalWidth,
          height: image.naturalHeight,
          alt,
        },
      ],
      bgOpacity: 1,
      counter: false,
      closeTitle: t("actions.close"),
      zoomTitle: t("actions.zoom"),
      arrowPrevTitle: t("actions.previous"),
      arrowNextTitle: t("actions.next"),
      errorMsg: t("errors.imageNotLoaded"),
    });

    pswp.on("uiRegister", () => {
      pswp.ui?.registerElement({
        name: "download-button",
        order: 9,
        isButton: true,
        tagName: "button",
        title: t("actions.download"),
        html: '<i class="fa fa-download"></i>',
        onClick: () => {
          const src = pswp.currSlide?.data.src;

          if (src) {
            void download(src, alt);
          }
        },
      });
    });

    pswp.init();
  };

  return { openImage };
};
