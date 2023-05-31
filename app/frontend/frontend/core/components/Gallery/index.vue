<template>
  <div class="pswp" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="pswp__bg" />
    <div class="pswp__scroll-wrap">
      <div class="pswp__container">
        <div class="pswp__item" />
        <div class="pswp__item" />
        <div class="pswp__item" />
      </div>
      <div class="pswp__ui pswp__ui--hidden">
        <div class="pswp__top-bar">
          <div class="pswp__counter" />
          <button
            class="pswp__button pswp__button--close"
            title="Close (Esc)"
          />
          <button class="pswp__button pswp__button--copy" @click="copyUrl">
            <i class="fa fa-copy" />
          </button>
          <button
            class="pswp__button pswp__button--fs"
            title="Toggle fullscreen"
          />
          <button class="pswp__button pswp__button--zoom" title="Zoom in/out" />
          <div class="pswp__preloader">
            <div class="pswp__preloader__icn">
              <div class="pswp__preloader__cut">
                <div class="pswp__preloader__donut" />
              </div>
            </div>
          </div>
        </div>
        <div
          class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap"
        >
          <div class="pswp__share-tooltip" />
        </div>
        <button
          class="pswp__button pswp__button--arrow--left"
          title="Previous (arrow left)"
        />
        <button
          class="pswp__button pswp__button--arrow--right"
          title="Next (arrow right)"
        />
        <div class="pswp__caption">
          <div class="pswp__caption__center" />
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import copyText from "@/frontend/utils/CopyText";
import PhotoSwipe from "photoswipe";
import PhotoSwipeUIDefault from "photoswipe/dist/photoswipe-ui-default";
import { useI18n } from "@/frontend/composables/useI18n";
import { useAppStore } from "@/frontend/stores/App";

type TGalleryImage = {
  src: string;
  w: number;
  h: number;
  msrc: string;
  el?: HTMLElement;
};

type Props = {
  items: TImage[];
};

const props = defineProps<Props>();

const gallery = ref<PhotoSwipe<PhotoSwipeUIDefault.Options> | null>(null);
const index = ref(0);

const galleryItems = computed<TGalleryImage[]>(() => {
  return props.items.map((item) => ({
    src: item.url,
    w: item.width,
    h: item.height,
    msrc: item.smallUrl,
    el: document.querySelector(`[href="${item.url}"]`) as HTMLElement,
  }));
});

const options = computed<PhotoSwipeUIDefault.Options>(() => {
  return {
    getThumbBoundsFn: getThumbBounds,
    index: index.value,
    showHideOpacity: true,
    loop: true,
    history: false,
    counterEl: false,
    shareEl: false,
  };
});

const { t } = useI18n();

const copyUrl = (_event: Event) => {
  copyText(gallery.value?.currItem.src || "").then(
    () => {
      displaySuccess({
        text: t("messages.copyImageUrl.success"),
      });
    },
    () => {
      displayAlert({
        text: t("messages.copyImageUrl.failure"),
      });
    }
  );
};

const getThumbBounds = (index: number) => {
  const item = galleryItems.value?.at(index);

  if (!item || !item.el) {
    return { x: 0, y: 0, w: 0 };
  }

  const pageYScroll = window.pageYOffset || document.documentElement.scrollTop;
  const rect = item.el.getBoundingClientRect();

  return { x: rect.left, y: rect.top + pageYScroll, w: rect.width };
};

const appStore = useAppStore();

const open = (newIndex = 0) => {
  index.value = parseInt(String(newIndex), 10);

  appStore.showOverlay();

  setup();

  gallery.value?.init();
};

const onClose = () => {
  appStore.hideOverlay();
};

const setup = () => {
  const pswpElement = document.querySelectorAll(".pswp")[0] as HTMLElement;

  gallery.value = new PhotoSwipe(
    pswpElement,
    PhotoSwipeUIDefault,
    galleryItems.value,
    options.value
  );

  gallery.value.listen("close", onClose);
};
</script>

<script lang="ts">
export default {
  name: "GalleryIndex",
};
</script>
