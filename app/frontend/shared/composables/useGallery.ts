import PhotoSwipeLightbox from "photoswipe/lightbox";
import copyText from "@/shared/utils/CopyText";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";

export const useGallery = (
  id: string = "#pswp-galley",
  children: string = ".gallery-image",
) => {
  const { t } = useI18n();

  const { displayAlert, displaySuccess } = useAppNotifications();

  const lightbox = ref<PhotoSwipeLightbox>();

  /*
   * Pass an element inside the open lightbox as `container`. Optional only
   * because copyText's own argument is - copying without one does not work
   * from in here, it just fails quietly.
   *
   * copyText hands clipboard.js a throwaway textarea to select and copy from,
   * and clipboard.js appends it to the container - document.body by default.
   * PhotoSwipe traps focus inside its own root while it is open, so a textarea
   * parked in body never takes the selection, and `execCommand("copy")` copies
   * an empty one. It still returns true, so clipboard.js reports success and
   * the notification below claimed the URL had been copied while the clipboard
   * kept whatever was in it before.
   */
  const copy = (url: string, container?: HTMLElement) => {
    copyText(url, container).then(
      () => {
        displaySuccess({
          text: t("messages.copyImageUrl.success"),
        });
      },
      () => {
        displayAlert({
          text: t("messages.copyImageUrl.failure"),
        });
      },
    );
  };

  const download = (url: string, name: string) => {
    const tmpLink = document.createElement("a");
    tmpLink.href = url;
    tmpLink.download = name;

    document.body.appendChild(tmpLink);

    tmpLink.click();

    document.body.removeChild(tmpLink);
  };

  const initGallery = () => {
    lightbox.value = new PhotoSwipeLightbox({
      gallery: id,
      children,
      bgOpacity: 1,
      counter: false,
      pswpModule: () => import("photoswipe"),
    });

    lightbox.value.on("uiRegister", () => {
      const pswp = lightbox.value?.pswp;
      pswp?.ui?.registerElement({
        name: "download-button",
        order: 8,
        isButton: true,
        tagName: "button",
        html: '<i class="fa fa-download"></i>',

        onClick: (_event, _el, pswp) => {
          const url = pswp.currSlide?.data.src;

          if (!url) {
            return;
          }

          download(
            url,
            pswp.currSlide?.data.title || pswp.currSlide?.data.alt || "image",
          );
        },
      });

      pswp?.ui?.registerElement({
        name: "copy-button",
        order: 7,
        isButton: true,
        tagName: "button",
        html: '<i class="fa fa-copy"></i>',
        onClick: (_event, _el, pswp) => {
          const url = pswp.currSlide?.data.src;

          if (!url) {
            return;
          }

          copy(url, pswp.element);
        },
      });

      pswp?.ui?.registerElement({
        name: "custom-caption",
        order: 9,
        isButton: false,
        appendTo: "root",
        html: "Caption text",
        onInit: (el, pswp) => {
          pswp.on("change", () => {
            const currSlideElement = pswp.currSlide?.data.element;
            let captionHTML = "";
            if (currSlideElement) {
              const hiddenCaption = currSlideElement.querySelector(
                ".hidden-caption-content",
              );
              if (hiddenCaption) {
                // get caption from element with class hidden-caption-content
                captionHTML = hiddenCaption.innerHTML;
              }
            }
            el.innerHTML = captionHTML || "";
          });
        },
      });
    });

    lightbox.value.init();
  };

  onMounted(() => {
    initGallery();
  });

  return {
    lightbox,
  };
};
