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

const { t } = useI18n();
const route = useRoute();

// Create image mapping using fixed keys
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
};

const tools: Array<Tool & { key: string }> = [
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
    key: "starship42",
    url: "https://starship42.com/",
    name: "Starship42",
    description: t("tools.descriptions.starship42"),
  },
  {
    key: "erkul",
    url: "https://erkul.games/",
    name: "Erkul",
    description: t("tools.descriptions.erkul"),
  },
  {
    key: "starjump",
    url: "https://hangar.link/fleet/canvas",
    name: "Starjump",
    description: t("tools.descriptions.starjump"),
  },
  {
    key: "itemFinder",
    url: "https://finder.cstone.space/",
    name: "Item Finder",
    description: t("tools.descriptions.itemFinder"),
  },
  {
    key: "starHangar",
    url: "https://star-hangar.com/",
    name: "Star Hangar",
    description: t("tools.descriptions.starHangar"),
  },
  {
    key: "shinytracker",
    url: "https://shinytracker.app/",
    name: "ShinyTracker",
    description: t("tools.descriptions.shinytracker"),
  },
  {
    key: "uexCorp",
    url: "https://uexcorp.space/",
    name: "UEX Corp",
    description: t("tools.descriptions.uexCorp"),
  },
];

const toolsWithImages = computed(() =>
  tools.map((tool) => ({
    ...tool,
    image: toolImages[tool.key],
  })),
);
</script>

<template>
  <Heading>{{ t(`headlines.${route.meta.title}`) }}</Heading>
  <div class="row">
    <div
      v-for="tool in toolsWithImages"
      :key="tool.key"
      class="col-12 col-md-6 col-lg-4 col-xl-3 col-xxl-2dot4"
    >
      <ToolCard
        :url="tool.url"
        :name="tool.name"
        :description="tool.description"
        :image="tool.image"
      />
    </div>
  </div>
</template>
