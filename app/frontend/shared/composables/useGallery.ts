import PhotoSwipeLightbox from "photoswipe/lightbox";
import copyText from "@/shared/utils/CopyText";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/shared/composables/useI18n";

export const useGallery = (
  id: string = "#pswp-galley",
  children: string = ".gallery-image",
) => {
  const { t } = useI18n();

  const { displayAlert, displaySuccess } = useNoty();

  const lightbox = ref<PhotoSwipeLightbox>();

  const copy = (url: string) => {
    copyText(url).then(
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

          copy(url);
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
