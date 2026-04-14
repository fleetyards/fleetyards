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
import {
  type FleetMember,
  FleetMembershipShipsFilterEnum,
} from "@/services/fyApi";

type Props = {
  members: FleetMember[];
};

const props = defineProps<Props>();

const mapContainer = ref<HTMLElement | null>(null);
let map: L.Map | null = null;

// --- Dev test data ---
const DEV_TEST = import.meta.env.DEV;

const GERMAN_CITIES = [
  [52.52, 13.41],
  [53.55, 9.99],
  [48.14, 11.58],
  [50.94, 6.96],
  [51.23, 6.78],
  [50.11, 8.68],
  [48.78, 9.18],
  [51.34, 12.37],
  [53.08, 8.81],
  [51.05, 13.74],
  [51.45, 7.01],
  [49.45, 11.08],
  [52.27, 10.52],
  [54.32, 10.14],
  [51.31, 9.5],
  [49.99, 8.27],
  [48.4, 10.0],
  [50.07, 8.24],
  [47.99, 7.84],
  [49.48, 8.47],
  [52.13, 11.63],
  [50.78, 6.08],
  [51.51, 7.47],
  [54.09, 12.13],
  [52.41, 9.74],
  [50.36, 7.6],
  [49.01, 8.4],
  [51.96, 7.63],
  [47.66, 9.18],
  [50.83, 12.92],
] as const;

function generateTestMembers(): FleetMember[] {
  const members: FleetMember[] = [];
  for (let i = 0; i < 120; i++) {
    const [baseLat, baseLng] = GERMAN_CITIES[i % GERMAN_CITIES.length];
    members.push({
      id: `test-${i}`,
      username: `Member_${i + 1}`,
      latitude: baseLat + (Math.random() - 0.5) * 1.5,
      longitude: baseLng + (Math.random() - 0.5) * 1.5,
      fleetRole: { id: "0", name: "member", slug: "member" },
      shipsFilter: FleetMembershipShipsFilterEnum.ALL,
      fleetSlug: "test",
      fleetName: "Test",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }
  return members;
}

const testMembers = DEV_TEST ? generateTestMembers() : [];

const allMembers = computed(() => {
  const real = props.members.filter(
    (m) => m.latitude != null && m.longitude != null,
  );
  return DEV_TEST ? [...real, ...testMembers] : real;
});

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

  for (const member of allMembers.value) {
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
  if (allMembers.value.length > 0) {
    const bounds = L.latLngBounds(
      allMembers.value.map(
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
