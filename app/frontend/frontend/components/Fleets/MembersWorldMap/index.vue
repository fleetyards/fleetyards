<script lang="ts">
export default {
  name: "MembersWorldMap",
};
</script>

<script lang="ts" setup>
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet.markercluster";
import "leaflet.markercluster/dist/MarkerCluster.css";
import type { FleetMember } from "@/services/fyApi";

type Props = {
  members: FleetMember[];
};

const props = defineProps<Props>();

const mapContainer = ref<HTMLElement | null>(null);
let map: L.Map | null = null;

const membersWithLocation = computed(() =>
  props.members.filter((m) => m.latitude != null && m.longitude != null),
);

// --- Member marker icon ---
const memberIcon = L.divIcon({
  className: "member-marker",
  iconSize: [8, 8],
  iconAnchor: [4, 4],
  popupAnchor: [0, -6],
});

onMounted(() => {
  if (!mapContainer.value) return;

  map = L.map(mapContainer.value, {
    center: [30, 10],
    zoom: 3,
    minZoom: 2,
    maxZoom: 12,
    zoomControl: true,
    attributionControl: false,
    worldCopyJump: true,
  });

  // Dark tile layer
  L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
    subdomains: "abcd",
    maxZoom: 19,
  }).addTo(map);

  // Cluster group with custom styling
  const clusters = L.markerClusterGroup({
    maxClusterRadius: 40,
    spiderfyOnMaxZoom: true,
    showCoverageOnHover: false,
    zoomToBoundsOnClick: true,
    iconCreateFunction(cluster) {
      const count = cluster.getChildCount();
      let size = "small";
      if (count >= 50) size = "large";
      else if (count >= 10) size = "medium";

      return L.divIcon({
        html: `<span>${count}</span>`,
        className: `member-cluster member-cluster-${size}`,
        iconSize: L.point(36, 36),
      });
    },
  });

  for (const member of membersWithLocation.value) {
    const marker = L.marker([member.latitude!, member.longitude!], {
      icon: memberIcon,
    });
    marker.bindPopup(`<strong>${member.username}</strong>`, {
      className: "member-popup",
    });
    clusters.addLayer(marker);
  }

  map.addLayer(clusters);

  // Fit bounds to members if any
  if (membersWithLocation.value.length > 0) {
    const bounds = L.latLngBounds(
      membersWithLocation.value.map(
        (m) => [m.latitude!, m.longitude!] as [number, number],
      ),
    );
    map.fitBounds(bounds, { padding: [60, 60], maxZoom: 6 });
  }
});

onUnmounted(() => {
  map?.remove();
  map = null;
});
</script>

<template>
  <div ref="mapContainer" class="members-worldmap" />
</template>

<style lang="scss" scoped>
.members-worldmap {
  height: calc(100vh - 300px);
  min-height: 400px;
  border-radius: 8px;
  overflow: hidden;
}
</style>

<style lang="scss">
.member-marker {
  background: rgb(143, 216, 216);
  border: 1px solid rgb(200, 240, 240);
  border-radius: 50%;
  box-shadow: 0 0 4px rgba(143, 216, 216, 0.5);
}

.member-cluster {
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-weight: 700;
  font-size: 0.75rem;
  color: #fff;

  span {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
  }

  &.member-cluster-small {
    background: rgba(143, 216, 216, 0.6);
    border: 2px solid rgba(143, 216, 216, 0.9);
    box-shadow: 0 0 8px rgba(143, 216, 216, 0.4);
  }

  &.member-cluster-medium {
    background: rgba(100, 190, 200, 0.6);
    border: 2px solid rgba(100, 190, 200, 0.9);
    box-shadow: 0 0 12px rgba(100, 190, 200, 0.4);
  }

  &.member-cluster-large {
    background: rgba(70, 160, 180, 0.6);
    border: 2px solid rgba(70, 160, 180, 0.9);
    box-shadow: 0 0 16px rgba(70, 160, 180, 0.4);
  }
}

.member-popup .leaflet-popup-content-wrapper {
  background: rgba(10, 22, 40, 0.95);
  color: rgb(143, 216, 216);
  border: 1px solid rgb(143, 216, 216);
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 600;
}

.member-popup .leaflet-popup-tip {
  background: rgba(10, 22, 40, 0.95);
  border: 1px solid rgb(143, 216, 216);
}
</style>
