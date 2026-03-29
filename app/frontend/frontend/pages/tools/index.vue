<script lang="ts">
export default {
  name: "ToolsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import ToolCard from "@/frontend/components/ToolCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { computed } from "vue";
import type { Tool } from "@/frontend/components/ToolCard/types";

// Import all tool images
import verseGuideImage from "@/images/tools/verse-guide.webp";
import starCitizenToolsImage from "@/images/tools/star-citizen-tools.webp";
import starship42Image from "@/images/tools/starship42.webp";
import erkulImage from "@/images/tools/erkul.webp";
import starjumpImage from "@/images/tools/starjump.webp";
import itemFinderImage from "@/images/tools/item-finder.webp";
import starHangarImage from "@/images/tools/star-hangar.webp";
import shinytrackerImage from "@/images/tools/shinytracker.webp";
import uexCorpImage from "@/images/tools/uex-corp.webp";
import cargoGridViewerImage from "@/images/tools/cargo-grid-viewer.webp";
import scmdbImage from "@/images/tools/scmdb.webp";
import regolithImage from "@/images/tools/regolith.webp";
import spviewerImage from "@/images/tools/spviewer.webp";

const { t } = useI18n();
const route = useRoute();

const toolImages: Record<string, string> = {
  verseGuide: verseGuideImage,
  starCitizenTools: starCitizenToolsImage,
  starship42: starship42Image,
  erkul: erkulImage,
  starjump: starjumpImage,
  itemFinder: itemFinderImage,
  starHangar: starHangarImage,
  shinytracker: shinytrackerImage,
  uexCorp: uexCorpImage,
  cargoGridViewer: cargoGridViewerImage,
  scmdb: scmdbImage,
  regolith: regolithImage,
  spviewer: spviewerImage,
};

type ToolEntry = Tool & { key: string; category?: string };

const featuredTools: Array<ToolEntry> = [
  {
    key: "scmdb",
    url: "https://scmdb.net/",
    name: "SCMDB // Mission Database",
    description: t("tools.descriptions.scmdb"),
    category: t("tools.categories.missions"),
  },
  {
    key: "erkul",
    url: "https://erkul.games/",
    name: "Erkul",
    description: t("tools.descriptions.erkul"),
    category: t("tools.categories.loadouts"),
  },
  {
    key: "regolith",
    url: "https://regolith.rocks/",
    name: "Regolith Co.",
    description: t("tools.descriptions.regolith"),
    category: t("tools.categories.mining"),
  },
];

const tools: Array<ToolEntry> = [
  {
    key: "spviewer",
    url: "https://www.spviewer.eu/",
    name: "SP Viewer",
    description: t("tools.descriptions.spviewer"),
  },
  {
    key: "uexCorp",
    url: "https://uexcorp.space/",
    name: "UEX Corp",
    description: t("tools.descriptions.uexCorp"),
  },
  {
    key: "itemFinder",
    url: "https://finder.cstone.space/",
    name: "Item Finder",
    description: t("tools.descriptions.itemFinder"),
  },
  {
    key: "cargoGridViewer",
    url: "https://sc-cargo.space/",
    name: "Cargo Grid Viewer",
    description: t("tools.descriptions.cargoGridViewer"),
  },
  {
    key: "verseGuide",
    url: "https://verseguide.com/",
    name: "Verse Guide",
    description: t("tools.descriptions.verseGuide"),
  },
  {
    key: "starCitizenTools",
    url: "https://starcitizen.tools/",
    name: "Star Citizen Tools",
    description: t("tools.descriptions.starCitizenTools"),
  },
  {
    key: "shinytracker",
    url: "https://shinytracker.app/",
    name: "ShinyTracker",
    description: t("tools.descriptions.shinytracker"),
  },
  {
    key: "starjump",
    url: "https://hangar.link/fleet/canvas",
    name: "Starjump",
    description: t("tools.descriptions.starjump"),
  },
  {
    key: "starHangar",
    url: "https://star-hangar.com/",
    name: "Star Hangar",
    description: t("tools.descriptions.starHangar"),
  },
];

const discontinuedTools: Array<ToolEntry> = [
  {
    key: "starship42",
    url: "https://starship42.com/",
    name: "Starship42",
    description: t("tools.descriptions.starship42"),
    disabled: true,
  },
];

const withImages = (list: Array<ToolEntry>) =>
  list.map((tool) => ({
    ...tool,
    image: toolImages[tool.key],
  }));

const featuredToolsWithImages = computed(() => withImages(featuredTools));
const toolsWithImages = computed(() => withImages(tools));
const discontinuedToolsWithImages = computed(() =>
  withImages(discontinuedTools),
);
</script>

<template>
  <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

  <div class="tools-featured">
    <ToolCard
      v-for="tool in featuredToolsWithImages"
      :key="tool.key"
      :url="tool.url"
      :name="tool.name"
      :description="tool.description"
      :image="tool.image"
      :category="tool.category"
      featured
    />
  </div>

  <div class="tools-grid">
    <ToolCard
      v-for="tool in toolsWithImages"
      :key="tool.key"
      :url="tool.url"
      :name="tool.name"
      :description="tool.description"
      :image="tool.image"
    />
  </div>

  <Heading level="h2" size="lg" class="tools-discontinued-heading">
    {{ t("tools.discontinuedHeading") }}
  </Heading>
  <div class="tools-grid">
    <ToolCard
      v-for="tool in discontinuedToolsWithImages"
      :key="tool.key"
      :url="tool.url"
      :name="tool.name"
      :description="tool.description"
      :image="tool.image"
      disabled
    />
  </div>
</template>

<style lang="scss" scoped>
.tools-featured {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 2rem;

  @media (max-width: 768px) {
    grid-template-columns: 1fr;
  }
}

.tools-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin-bottom: 2rem;

  @media (max-width: 1200px) {
    grid-template-columns: repeat(3, 1fr);
  }

  @media (max-width: 768px) {
    grid-template-columns: repeat(2, 1fr);
  }

  @media (max-width: 480px) {
    grid-template-columns: 1fr;
  }
}

.tools-discontinued-heading {
  margin-bottom: 0.75rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid rgba(white, 0.1);
  color: $gray-lighter;
}
</style>
