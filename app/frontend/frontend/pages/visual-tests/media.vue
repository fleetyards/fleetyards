<script lang="ts">
export default {
  name: "VisualTestsMediaPage",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import VideoPlayer from "@/shared/components/Video/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import { ViewImageSizeEnum } from "@/shared/components/ViewImage/types";
import { useCookiesStore } from "@/frontend/stores/cookies";
import { VideoTypeEnum, type MediaFile } from "@/services/fyApi";
import { storeToRefs } from "pinia";
import logo from "@/images/logo.png";
import rsiLogo from "@/images/rsi_logo.png";
import storeImage from "@/images/fallback/store_image.webp";

/*
 * The four media components share one problem: what they show when the image is
 * not there. Each falls back differently - a bundled placeholder, an icon, or
 * nothing at all - and a URL that resolves to nothing is a different case again
 * from one that was never set.
 */

// Deliberately unreachable, to show a src that resolves to nothing. Distinct
// from `undefined`, which is what makes a component reach for its fallback.
const brokenSrc = "/images/this-file-does-not-exist.png";

const file = (url: string): MediaFile => ({
  name: "store_image.webp",
  contentType: "image/webp",
  size: 48_000,
  url,
  smallUrl: url,
  mediumUrl: url,
  largeUrl: url,
  xlargeUrl: url,
  width: 1920,
  height: 1080,
});

const lazyVariants = Object.values(LazyImageVariantsEnum);
const viewSizes = Object.values(ViewImageSizeEnum);

const avatarSizes = ["small", "default", "large"] as const;

const uploads = ref<string[]>([]);

const onUpload = () => {
  uploads.value = ["upload", ...uploads.value].slice(0, 4);
};

const onDestroy = () => {
  uploads.value = ["destroy", ...uploads.value].slice(0, 4);
};

// Video renders nothing but a consent prompt until YouTube is accepted, and the
// store has no action to take it back, so the demo writes the state directly.
const cookiesStore = useCookiesStore();

const { youtubeAccepted } = storeToRefs(cookiesStore);

const toggleYoutube = () => {
  cookiesStore.cookies.youtube = !cookiesStore.cookies.youtube;
};

const video = {
  id: "vt-video",
  type: VideoTypeEnum.YOUTUBE,
  url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  videoId: "dQw4w9WgXcQ",
  createdAt: "2029-01-01T00:00:00.000Z",
  updatedAt: "2029-01-01T00:00:00.000Z",
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Avatar | Sizes</Heading>
  <p>
    Round by default. Without an <code>avatar</code> it falls back to an icon
    rather than to a placeholder image.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <Avatar
        v-for="size in avatarSizes"
        :key="size"
        :avatar="logo"
        :size="size"
      />
      <Avatar :avatar="logo" size="large" :round="false" />
      <Avatar size="large" />
      <Avatar size="large" icon="fa-duotone fa-users" />
      <Avatar :avatar="brokenSrc" size="large" />
      <Avatar :avatar="logo" size="large" transparent />
    </div>
  </div>
  <p class="text-muted">
    Left to right: three sizes, square, no image, a different fallback icon, a
    src that resolves to nothing, and transparent.
  </p>

  <Heading :level="HeadingLevelEnum.H2">Avatar | Editable</Heading>
  <p>
    <code>editable</code> offers upload and remove, <code>creatable</code> only
    upload. Both emit rather than upload anything themselves.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <Avatar
        :avatar="logo"
        size="large"
        editable
        @upload="onUpload"
        @destroy="onDestroy"
      />
      <Avatar size="large" creatable @upload="onUpload" />
      <BaseText muted no-spacing>
        Emitted: {{ uploads.length ? uploads.join(", ") : "—" }}
      </BaseText>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">LazyImage | Variants</Heading>
  <p>
    The variant sets the aspect ratio the image is cropped into. Images load
    only once they are near the viewport.
  </p>
  <div class="row">
    <div v-for="variant in lazyVariants" :key="variant" class="col-12 col-lg-6">
      <BaseText muted no-spacing>{{ variant }}</BaseText>
      <LazyImage :src="storeImage" :variant="variant" alt="Store image" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">LazyImage | Missing and broken</Heading>
  <p>
    Both end at the same bundled placeholder: a missing <code>src</code> never
    loads anything, and one that resolves to nothing falls back after failing.
    So the two are indistinguishable by eye — only the class differs, which is
    worth knowing before hunting a "wrong image" bug in the wrong layer.
  </p>
  <div class="row">
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>no src — never loads</BaseText>
      <LazyImage :variant="LazyImageVariantsEnum.SMALL" alt="Missing" />
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>broken src — falls back</BaseText>
      <LazyImage
        :src="brokenSrc"
        :variant="LazyImageVariantsEnum.SMALL"
        alt="Broken"
      />
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>transparent</BaseText>
      <LazyImage
        :src="rsiLogo"
        :variant="LazyImageVariantsEnum.SMALL"
        alt="RSI"
        transparent
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2"
    >LazyImage | Caption, shadow, link</Heading
  >
  <p>
    A caption sits under the frame. With <code>href</code> or
    <code>to</code> the whole frame becomes the link.
  </p>
  <div class="row">
    <div class="col-12 col-lg-4">
      <LazyImage
        :src="storeImage"
        :variant="LazyImageVariantsEnum.SMALL"
        alt="With caption"
        caption="Aegis Idris P"
      />
    </div>
    <div class="col-12 col-lg-4">
      <LazyImage
        :src="storeImage"
        :variant="LazyImageVariantsEnum.SMALL"
        alt="With shadow"
        shadow
      />
    </div>
    <div class="col-12 col-lg-4">
      <LazyImage
        :src="storeImage"
        :variant="LazyImageVariantsEnum.SMALL"
        alt="As a link"
        :to="{ name: 'visual-tests-media' }"
        caption="Links back to this page"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">ViewImage | Sizes</Heading>
  <p>
    Takes a <code>MediaFile</code> and picks the URL for the requested size. All
    five point at the same file here, so the frames differ and the image does
    not.
  </p>
  <div class="row">
    <div v-for="size in viewSizes" :key="size" class="col-12 col-lg-4">
      <BaseText muted no-spacing>{{ size }}</BaseText>
      <ViewImage :image="file(storeImage)" :size="size" alt="Store image" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">ViewImage | Without an image</Heading>
  <p>
    No image falls back to the placeholder;
    <code>withoutFallback</code> renders nothing at all, which is what a card
    wants when it must not show a frame it cannot fill.
  </p>
  <div class="row">
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>no image — placeholder</BaseText>
      <ViewImage alt="Missing" />
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>withoutFallback — nothing</BaseText>
      <ViewImage alt="Missing" without-fallback />
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>broken url</BaseText>
      <ViewImage :image="file(brokenSrc)" alt="Broken" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Video</Heading>
  <p>
    The embed is withheld until YouTube cookies are accepted, so the consent
    prompt is the state most people see. The store has no action to take the
    acceptance back, so this toggle writes the flag directly.
  </p>
  <div class="row">
    <div class="col-12 vt-row">
      <Btn data-test="toggle-youtube-consent" @click="toggleYoutube">
        {{ youtubeAccepted ? "Withdraw" : "Accept" }} YouTube cookies
      </Btn>
      <BaseText muted no-spacing>
        youtubeAccepted: {{ youtubeAccepted }}
      </BaseText>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <VideoPlayer :video="video" />
    </div>
  </div>
</template>
