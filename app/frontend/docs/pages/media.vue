<script lang="ts">
export default {
  name: "MediaPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import type { BaseTableCol } from "@/shared/components/base/Table/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";
import LinkBuilder from "@/docs/components/LinkBuilder/index.vue";
import { useCopy } from "@/docs/composables/useCopy";

type MediaAsset = {
  key: string;
  name: string;
  file: string;
  format: string;
  dimensions: string;
  description: string;
};

type LinkPattern = {
  name: string;
  path: string;
  note: string;
};

const frontendEndpoint = window.FRONTEND_ENDPOINT;

const assetUrl = (file: string) => `${frontendEndpoint}/media/${file}`;

// The download attribute only works on a same-origin link. The docs host is
// served by the same app as the frontend, so a root-relative path is the same
// file on the docs origin.
const downloadPath = (file: string) => `/media/${file}`;

const banner: MediaAsset = {
  key: "banner",
  name: "Banner",
  file: "fleetyards-banner.jpg",
  format: "JPG",
  dimensions: "3440 × 1440",
  description: "Stream overlays, video thumbnails, page headers",
};

const logos: MediaAsset[] = [
  {
    key: "logo",
    name: "Logo",
    file: "fleetyards-logo.png",
    format: "PNG",
    dimensions: "512 × 344",
    description:
      "The full mark with its ring. The first choice wherever there is room.",
  },
  {
    key: "icon",
    name: "Icon",
    file: "fleetyards-icon.png",
    format: "PNG",
    dimensions: "512 × 512",
    description:
      "The round mark alone, for avatars, app tiles and other square spaces.",
  },
  {
    key: "icon-128",
    name: "Icon, small",
    file: "fleetyards-icon-128.png",
    format: "PNG",
    dimensions: "128 × 128",
    description: "Sized for buttons, badges and link lists.",
  },
  {
    key: "wordmark",
    name: "Logo with name",
    file: "fleetyards-wordmark.png",
    format: "PNG",
    dimensions: "570 × 212",
    description:
      "The mark above the FleetYards.net name. The light lettering needs a dark background.",
  },
];

const dos = [
  "Link the logo to FleetYards.net wherever you show it.",
  "Use it to show that your site, stream or tool uses FleetYards.net data.",
  "Give it room, and pick the file that fits the space.",
];

const donts = [
  "Recolour, stretch, crop or redraw the mark.",
  "Use it as the logo of your own project.",
  "Suggest that FleetYards.net runs, sponsors or endorses what you make.",
];

const linkPatterns: LinkPattern[] = [
  {
    name: "Ship",
    path: "/ships/<slug>/",
    note: "Slugs are listed at api.fleetyards.net/v1/models/slugs.",
  },
  {
    name: "Hangar",
    path: "/hangar/<username>/",
    note: "Public hangars only.",
  },
  {
    name: "Fleet",
    path: "/fleets/<fleet-id>/",
    note: "Public fleets only.",
  },
  {
    name: "Ship database",
    path: "/ships/",
    note: "Every ship and vehicle.",
  },
];

const linkColumns: BaseTableCol<LinkPattern>[] = [
  { name: "name", label: "Page", width: "18%" },
  { name: "path", label: "Address" },
  { name: "note", label: "Note" },
];

const { copy } = useCopy();

const scrollTo = (id: string) => {
  document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });
};
</script>

<template>
  <div class="media-page__intro">
    <div class="media-page__intro-text">
      <Heading :size="HeadingSizeEnum.HERO" hero>Media &amp; Linking</Heading>
      <BaseText no-spacing>
        Logos, a banner and ready-made links for fleet sites, streams, videos
        and tools that point to FleetYards.net. Every file below has a permanent
        address, so you can link it or download it.
      </BaseText>
    </div>
    <div class="media-page__intro-actions">
      <Btn variant="ghost" size="md" @click="scrollTo('linking')">
        <i class="fa-light fa-link" aria-hidden="true"></i>
        <span>Linking</span>
      </Btn>
      <Btn variant="ghost" size="md" @click="scrollTo('embedding')">
        <i class="fa-light fa-code" aria-hidden="true"></i>
        <span>Embedding</span>
      </Btn>
    </div>
  </div>

  <Panel data-test="media-asset-banner">
    <img
      class="media-page__banner"
      :src="assetUrl(banner.file)"
      alt="FleetYards.net banner: the logo and name over a Star Citizen city at night"
    />
    <PanelBody class="media-page__banner-body">
      <div class="media-page__facts">
        <div>
          <div class="media-page__label">{{ banner.name }}</div>
          <div class="media-page__value">
            {{ banner.format }} · {{ banner.dimensions }}
          </div>
        </div>
        <div>
          <div class="media-page__label">Use for</div>
          <div class="media-page__value">{{ banner.description }}</div>
        </div>
      </div>
      <div class="media-page__actions">
        <Btn
          :href="downloadPath(banner.file)"
          target="_self"
          :download="banner.file"
        >
          <i class="fa-light fa-download" aria-hidden="true"></i>
          <span>Download</span>
        </Btn>
        <Btn variant="ghost" @click="copy(assetUrl(banner.file))">
          <i class="fa-light fa-copy" aria-hidden="true"></i>
          <span>Copy URL</span>
        </Btn>
      </div>
    </PanelBody>
  </Panel>

  <Heading :level="HeadingLevelEnum.H2" :size="HeadingSizeEnum.XXL" mt>
    Logos
  </Heading>
  <BaseText muted>
    Transparent PNGs. Use them as they are, without recolouring, cropping or
    effects.
  </BaseText>

  <div class="media-page__logos">
    <Panel
      v-for="logo in logos"
      :key="logo.key"
      :outer-spacing="false"
      fill-height
      :data-test="`media-asset-${logo.key}`"
    >
      <div class="media-page__preview">
        <img :src="assetUrl(logo.file)" :alt="logo.name" loading="lazy" />
      </div>
      <PanelBody class="media-page__logo-body">
        <Heading :level="HeadingLevelEnum.H3" :size="HeadingSizeEnum.XL" hero>
          {{ logo.name }}
        </Heading>
        <div class="media-page__facts">
          <div>
            <div class="media-page__label">Format</div>
            <div class="media-page__value">{{ logo.format }}</div>
          </div>
          <div>
            <div class="media-page__label">Size</div>
            <div class="media-page__value">{{ logo.dimensions }}</div>
          </div>
        </div>
        <BaseText no-spacing class="media-page__description">
          {{ logo.description }}
        </BaseText>
        <code class="media-page__url">{{ assetUrl(logo.file) }}</code>
        <div class="media-page__actions">
          <Btn
            :href="downloadPath(logo.file)"
            target="_self"
            :download="logo.file"
          >
            <i class="fa-light fa-download" aria-hidden="true"></i>
            <span>Download</span>
          </Btn>
          <Btn variant="ghost" @click="copy(assetUrl(logo.file))">
            <i class="fa-light fa-copy" aria-hidden="true"></i>
            <span>Copy URL</span>
          </Btn>
        </div>
      </PanelBody>
    </Panel>
  </div>

  <Heading :level="HeadingLevelEnum.H2" :size="HeadingSizeEnum.XXL" mt>
    Using the logo
  </Heading>
  <div class="media-page__rules">
    <Panel variant="slim" :outer-spacing="false">
      <PanelBody class="media-page__rule-list">
        <div class="media-page__label">Please do</div>
        <div v-for="rule in dos" :key="rule" class="media-page__rule">
          <i class="fa-light fa-check" aria-hidden="true"></i>
          <span>{{ rule }}</span>
        </div>
      </PanelBody>
    </Panel>
    <Panel variant="slim" :outer-spacing="false">
      <PanelBody class="media-page__rule-list">
        <div class="media-page__label">Please don't</div>
        <div v-for="rule in donts" :key="rule" class="media-page__rule">
          <i class="fa-light fa-xmark" aria-hidden="true"></i>
          <span>{{ rule }}</span>
        </div>
      </PanelBody>
    </Panel>
  </div>

  <div id="linking">
    <Heading :level="HeadingLevelEnum.H2" :size="HeadingSizeEnum.XXL" mt>
      Linking to FleetYards.net
    </Heading>
  </div>
  <BaseText muted>
    Pages have stable addresses. Hangars and fleets only open for visitors when
    their owner has set them to public.
  </BaseText>

  <Panel>
    <PanelHeading>Build a link</PanelHeading>
    <PanelBody>
      <LinkBuilder
        :frontend-endpoint="frontendEndpoint"
        :icon-url="assetUrl('fleetyards-icon-128.png')"
      />
    </PanelBody>
  </Panel>

  <BaseTable
    :records="linkPatterns"
    :columns="linkColumns"
    primary-key="path"
    data-test="media-link-patterns"
  >
    <template #col-path="{ record }">
      <code class="media-page__path"
        >{{ frontendEndpoint }}{{ record.path }}</code
      >
    </template>
  </BaseTable>

  <div id="embedding">
    <Heading :level="HeadingLevelEnum.H2" :size="HeadingSizeEnum.XXL" mt>
      Embedding
    </Heading>
  </div>
  <div class="media-page__embedding">
    <Panel>
      <PanelBody class="media-page__teaser">
        <i
          class="fa-duotone fa-arrow-up-from-square media-page__teaser-icon"
          aria-hidden="true"
        ></i>
        <div class="media-page__teaser-content">
          <Heading :level="HeadingLevelEnum.H3" :size="HeadingSizeEnum.XL" hero>
            Embed Widget
          </Heading>
          <BaseText no-spacing>
            Show a ship list or a fleetchart for ships, a hangar or a fleet on
            your own page, from a few lines of HTML.
          </BaseText>
          <Btn :to="{ name: 'embed' }">
            <span>Set up the widget</span>
            <i class="fa-light fa-chevron-right" aria-hidden="true"></i>
          </Btn>
        </div>
      </PanelBody>
    </Panel>
    <Panel>
      <PanelBody class="media-page__teaser">
        <i
          class="fa-duotone fa-brackets-curly media-page__teaser-icon"
          aria-hidden="true"
        ></i>
        <div class="media-page__teaser-content">
          <Heading :level="HeadingLevelEnum.H3" :size="HeadingSizeEnum.XL" hero>
            Ship images from the API
          </Heading>
          <BaseText no-spacing>
            Every ship carries its store image, side, top and front views and
            fleetchart image under <code>media</code>.
          </BaseText>
          <Btn :to="{ name: 'api-v1' }">
            <span>Open the API docs</span>
            <i class="fa-light fa-chevron-right" aria-hidden="true"></i>
          </Btn>
        </div>
      </PanelBody>
    </Panel>
  </div>

  <BaseText muted class="media-page__disclaimer">
    FleetYards.net is an unofficial Star Citizen fan site, not affiliated with
    the Cloud Imperium group of companies. Ship images, renders and other game
    content, including the artwork in the banner, belong to Cloud Imperium
    Games; their fan content rules apply to them, not this page.
  </BaseText>
</template>

<style lang="scss" scoped>
@import "@/shared/components/rowLabel";

.media-page__intro {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 1.5rem;
  margin-bottom: 1.5rem;
}

.media-page__intro-text {
  flex: 1 1 520px;
  min-width: 0;
  max-width: 680px;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.media-page__intro-actions,
.media-page__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.media-page__banner {
  display: block;
  width: 100%;
  aspect-ratio: 43 / 18;
  object-fit: cover;
  border-radius: var(--radius-surface-inner) var(--radius-surface-inner) 0 0;
}

.media-page__banner-body {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.media-page__facts {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem 2rem;
}

.media-page__label {
  @include row-label;
  font-size: 10px;
}

.media-page__value {
  font-size: 13.5px;
  line-height: 1.3;
  font-weight: 600;
  color: var(--color-lifted);
}

.media-page__logos {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  margin-bottom: 1.5rem;
}

.media-page__preview {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 200px;
  padding: 1.5rem;
  background: var(--color-gray-black);
  border-radius: var(--radius-surface-inner) var(--radius-surface-inner) 0 0;

  img {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
  }
}

.media-page__logo-body {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  flex-grow: 1;
}

.media-page__description {
  flex-grow: 1;
}

.media-page__url,
.media-page__path {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  overflow-wrap: anywhere;
}

.media-page__url {
  display: block;
  padding: 0.5rem 0.625rem;
  background: var(--color-field);
  border: 1px solid var(--color-edge);
  border-radius: 8px;
  font-size: 12px;
  line-height: 1.4;
}

.media-page__path {
  font-size: 13px;
  color: var(--color-lifted);
}

.media-page__rules,
.media-page__embedding {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 320px), 1fr));
  gap: 1.5rem;
}

.media-page__rules {
  margin-bottom: 1.5rem;
}

.media-page__rule-list {
  display: flex;
  flex-direction: column;
  gap: 0.875rem;
}

.media-page__rule {
  display: flex;
  gap: 0.75rem;

  i {
    padding-top: 0.25rem;
    color: var(--color-text-dim);
  }
}

.media-page__teaser {
  display: flex;
  gap: 1.25rem;
  align-items: flex-start;
}

.media-page__teaser-icon {
  font-size: 2rem;
  opacity: 0.5;
  padding-top: 0.25rem;
}

.media-page__teaser-content {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.75rem;
}

.media-page__disclaimer {
  max-width: 860px;
}
</style>
