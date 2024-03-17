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
import PhotoSwipe from "photoswipe";
import PhotoSwipeUIDefault from "photoswipe/dist/photoswipe-ui-default";
import copyText from "@/shared/utils/CopyText";
import { useNoty } from "@/shared/composables/useNoty";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
import { useOverlayStore } from "@/shared/stores/overlay";
import { type Image } from "@/services/fyApi";

const i18n = inject<I18nPluginOptions>("i18n");

const { displayAlert, displaySuccess } = useNoty(i18n!.t);

type Props = {
  items?: Array<Image>;
};

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
});

const gallery = ref<PhotoSwipe<PhotoSwipe.Options>>();

const internalIndex = ref(0);

const galleryItems = computed(() => {
  if (!props.items) {
    return [];
  }

  return props.items.map((item) => ({
    src: item.url,
    w: item.width,
    h: item.height,
    msrc: item.smallUrl,
    el: document.querySelector(`[href="${item.url}"]`),
  }));
});

const options = computed(() => {
  return {
    getThumbBoundsFn: getThumbBounds,
    index: unref(internalIndex),
    showHideOpacity: true,
    loop: true,
    history: false,
    counterEl: false,
    shareEl: false,
  };
});

const copyUrl = (_event: Event) => {
  copyText(gallery.value?.currItem.src || "").then(
    () => {
      displaySuccess({
        text: i18n?.t("messages.copyImageUrl.success"),
      });
    },
    () => {
      displayAlert({
        text: i18n?.t("messages.copyImageUrl.failure"),
      });
    },
  );
};

const getThumbBounds = (index: number) => {
  if (!galleryItems.value[index] || !galleryItems.value[index].el) {
    return { x: 0, y: 0, w: 0 };
  }

  const pageYScroll = window.pageYOffset || document.documentElement.scrollTop;
  const rect = galleryItems.value[index].el?.getBoundingClientRect();

  if (!rect) {
    return { x: 0, y: 0, w: 0 };
  }

  return { x: rect.left, y: rect.top + pageYScroll, w: rect.width };
};

const overlayStore = useOverlayStore();

const open = (index = 0) => {
  internalIndex.value = +index;

  overlayStore.show();

  setup();

  gallery.value?.init();
};

const onClose = () => {
  overlayStore.hide();
};

const setup = () => {
  const pswpElement = document.querySelectorAll(".pswp")[0] as HTMLElement;

  gallery.value = new PhotoSwipe(
    pswpElement,
    PhotoSwipeUIDefault,
    unref(galleryItems),
    unref(options),
  );

  gallery.value.listen("close", onClose);
};

defineExpose({
  open,
});
</script>

<script lang="ts">
export default {
  name: "GalleryComponent",
};
</script>
