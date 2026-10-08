import { useI18n } from "@/shared/composables/useI18n";
import {
  photoSwipeTitles,
  registerDownloadButton,
} from "@/shared/utils/PhotoSwipe";

// One image full size, for an image with no stored dimensions: PhotoSwipe needs
// them up front, so they are read off the already loaded thumbnail, which is
// the same file.
export const useImageViewer = () => {
  const { t } = useI18n();

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
      ...photoSwipeTitles(t),
    });

    pswp.on("uiRegister", () => {
      registerDownloadButton(pswp, t, () => alt);
    });

    pswp.init();
  };

  return { openImage };
};
