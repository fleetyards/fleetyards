<script lang="ts">
export default {
  name: "ToolsPage",
};
</script>

<script lang="ts" setup>
const tools = [
  {
    url: "https://verseguide.com/",
    name: "Verse Guide",
    description: "Travel Guide for the Star Citizen universe",
    image: undefined,
  },
  {
    url: "https://starcitizen.tools/",
    name: "Star Citizen Tools",
    description: "Star Citizen Wiki",
    image: undefined,
  },
  {
    url: "https://starship42.com/",
    name: "Starship42",
    description: "3D Ship Viewer",
    image: undefined,
  },
  {
    url: "https://erkul.games/",
    name: "Erkul",
    description: "DPS Calculator",
    image: undefined,
  },
  {
    url: "https://starjump.space/",
    name: "Starjump",
    description: "2D Ship Viewer",
    image: undefined,
  },
  {
    url: "https://finder.cstone.space/",
    name: "Item Finder",
    description: "Find items in the verse",
    image: undefined,
  },
  {
    url: "https://star-hangar.com/",
    name: "Star Hangar",
    description: "Star Citizen Pledge/Ship Market Place",
    image: undefined,
  },
  {
    url: "https://shinytracker.app/",
    name: "ShinyTracker",
    description: "Star Citizen Progress Tracker",
    image: undefined,
  },
  {
    url: "https://uexcorp.space/",
    name: "UEX Corp",
    description: "Star Citizen Commodity and Item Finder",
    image: undefined,
  },
];
</script>

<template>
  <div>
    <ul>
      <li v-for="tool in tools" :key="tool.name">
        <a :href="tool.url" target="_blank">{{ tool.name }}</a>
      </li>
    </ul>
  </div>
</template>
