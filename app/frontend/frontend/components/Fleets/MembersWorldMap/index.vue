<script lang="ts">
export default {
  name: "MembersWorldMap",
};
</script>

<script lang="ts" setup>
import {
  SphereGeometry,
  ShaderMaterial,
  MeshBasicMaterial,
  SpriteMaterial,
  AdditiveBlending,
  Color,
  QuadraticBezierCurve3,
  Vector3,
  TubeGeometry,
  TextureLoader,
  CanvasTexture,
  LinearFilter,
  Float32BufferAttribute,
  BufferGeometry,
  PointsMaterial,
} from "three";
import { TresCanvas } from "@tresjs/core";
import { OrbitControls } from "@tresjs/cientos";
import { useMobile } from "@/shared/composables/useMobile";
import type { FleetMember } from "@/services/fyApi";
import earthTextureSrc from "@/images/earth_dark.jpg";

type Props = {
  members: FleetMember[];
};

const props = defineProps<Props>();

const mobile = useMobile();

const dpr = computed(() =>
  mobile.value
    ? Math.min(window.devicePixelRatio, 1.5)
    : window.devicePixelRatio * 1.5,
);

const powerPreference = computed<WebGLPowerPreference>(() =>
  mobile.value ? "low-power" : "default",
);

const GLOBE_RADIUS = 200;
const MARKER_OFFSET = GLOBE_RADIUS + GLOBE_RADIUS * 0.025;

// --- Coordinate conversion ---
function toSphereCoords(
  lat: number,
  lng: number,
  radius: number,
): [number, number, number] {
  const phi = ((90 - lat) * Math.PI) / 180;
  const theta = -(lng * Math.PI) / 180;
  const x = radius * Math.sin(phi) * Math.cos(theta);
  const y = radius * Math.cos(phi);
  const z = radius * Math.sin(phi) * Math.sin(theta);
  return [x, y, z];
}

// --- Dev test data: 120 fake members scattered across Germany ---
const DEV_TEST = import.meta.env.DEV;

const GERMAN_CITIES = [
  [52.52, 13.41], [53.55, 9.99], [48.14, 11.58], [50.94, 6.96],
  [51.23, 6.78], [50.11, 8.68], [48.78, 9.18], [51.34, 12.37],
  [53.08, 8.81], [51.05, 13.74], [51.45, 7.01], [49.45, 11.08],
  [52.27, 10.52], [54.32, 10.14], [51.31, 9.5], [49.99, 8.27],
  [48.4, 10.0], [50.07, 8.24], [47.99, 7.84], [49.48, 8.47],
  [52.13, 11.63], [50.78, 6.08], [51.51, 7.47], [54.09, 12.13],
  [52.41, 9.74], [50.36, 7.6], [49.01, 8.4], [51.96, 7.63],
  [47.66, 9.18], [50.83, 12.92],
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
      shipsFilter: "public" as any,
      fleetSlug: "test",
      fleetName: "Test",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }
  return members;
}

const testMembers = DEV_TEST ? generateTestMembers() : [];

// --- Members ---
const allMembers = computed(() => {
  const real = props.members.filter(
    (m) => m.latitude != null && m.longitude != null,
  );
  return DEV_TEST ? [...real, ...testMembers] : real;
});

// --- Marker clustering ---
interface MarkerCluster {
  id: string;
  position: [number, number, number];
  members: FleetMember[];
  lat: number;
  lng: number;
}

const CLUSTER_THRESHOLD = 5; // degrees (~500km)

function clusterMembers(members: FleetMember[]): MarkerCluster[] {
  const clusters: MarkerCluster[] = [];

  for (const member of members) {
    const lat = member.latitude!;
    const lng = member.longitude!;

    let added = false;
    for (const cluster of clusters) {
      const dLat = lat - cluster.lat;
      const dLng = lng - cluster.lng;
      if (Math.sqrt(dLat * dLat + dLng * dLng) < CLUSTER_THRESHOLD) {
        cluster.members.push(member);
        // Recalculate centroid
        cluster.lat =
          cluster.members.reduce((s, m) => s + m.latitude!, 0) /
          cluster.members.length;
        cluster.lng =
          cluster.members.reduce((s, m) => s + m.longitude!, 0) /
          cluster.members.length;
        cluster.position = toSphereCoords(
          cluster.lat,
          cluster.lng,
          MARKER_OFFSET,
        );
        added = true;
        break;
      }
    }

    if (!added) {
      clusters.push({
        id: member.id,
        position: toSphereCoords(lat, lng, MARKER_OFFSET),
        members: [member],
        lat,
        lng,
      });
    }
  }

  return clusters;
}

const markerClusters = computed(() => clusterMembers(allMembers.value));

// Marker size based on cluster count
function clusterScale(count: number): number {
  if (count <= 1) return 1;
  return Math.min(1 + Math.log2(count) * 0.4, 3);
}

// --- Globe with earth texture + rim glow ---
const earthTexture = new TextureLoader().load(earthTextureSrc);
const globeGeometry = new SphereGeometry(GLOBE_RADIUS, 64, 64);

const globeMaterial = new ShaderMaterial({
  uniforms: { globeTexture: { value: earthTexture } },
  vertexShader: `
    varying vec3 vNormal;
    varying vec2 vUv;
    void main() {
      vNormal = normalize(normalMatrix * normal);
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    uniform sampler2D globeTexture;
    varying vec3 vNormal;
    varying vec2 vUv;
    void main() {
      vec3 diffuse = texture2D(globeTexture, vUv).xyz;
      float intensity = 1.05 - dot(vNormal, vec3(0.0, 0.0, 1.0));
      vec3 atmosphere = vec3(1.0, 1.0, 1.0) * pow(intensity, 3.0);
      gl_FragColor = vec4(diffuse + atmosphere, 1.0);
    }
  `,
  blending: AdditiveBlending,
  transparent: true,
});

// --- Connection arcs between members ---
interface ArcEntry {
  curve: QuadraticBezierCurve3;
  geometry: TubeGeometry;
}

function getSplineCoords(
  latA: number,
  lngA: number,
  latB: number,
  lngB: number,
  radius: number,
) {
  const start = new Vector3(...toSphereCoords(latA, lngA, radius));
  const end = new Vector3(...toSphereCoords(latB, lngB, radius));

  const altitude = Math.min(
    Math.max(start.distanceTo(end) * 0.45, 20),
    200,
  );

  const mid = new Vector3()
    .addVectors(start, end)
    .multiplyScalar(0.5);
  mid.normalize().multiplyScalar(GLOBE_RADIUS + altitude);

  return { start, mid, end };
}

const arcData = computed<ArcEntry[]>(() => {
  const clusters = markerClusters.value;
  if (clusters.length < 2) return [];

  const arcs: ArcEntry[] = [];
  for (let i = 0; i < clusters.length; i++) {
    const j = (i + 1) % clusters.length;
    const { start, mid, end } = getSplineCoords(
      clusters[i].lat,
      clusters[i].lng,
      clusters[j].lat,
      clusters[j].lng,
      MARKER_OFFSET,
    );

    const curve = new QuadraticBezierCurve3(start, mid, end);
    arcs.push({
      curve,
      geometry: new TubeGeometry(curve, 200, 0.5, 8, false),
    });
  }
  return arcs;
});

const arcMaterial = new MeshBasicMaterial({
  color: new Color("rgb(255, 255, 255)"),
  transparent: true,
  opacity: 0.45,
});

// --- Traveling dots along arcs ---
const MAX_DOTS = 30;
const dotsArray = new Float32Array(MAX_DOTS * 3).fill(99999);
const dotsGeometry = new BufferGeometry();
dotsGeometry.setAttribute(
  "position",
  new Float32BufferAttribute(dotsArray, 3),
);

const dotsMaterial = new PointsMaterial({
  color: new Color("rgb(255, 255, 255)"),
  size: 4,
  transparent: true,
  opacity: 0.65,
});

interface TravelingDot {
  pathIndex: number;
  path: Vector3[] | null;
}

const travelingDots: TravelingDot[] = Array.from(
  { length: MAX_DOTS },
  () => ({ pathIndex: 0, path: null }),
);

// --- Marker materials ---
const markerGeometry = new SphereGeometry(2, 15, 15);

const markerMaterial = new MeshBasicMaterial({
  color: new Color("rgb(143, 216, 216)"),
  transparent: true,
  opacity: 0.8,
});

// Per-marker glow state
interface GlowState {
  isAnimating: boolean;
  scale: number;
  opacity: number;
  material: MeshBasicMaterial;
}

const glowStates = computed<GlowState[]>(() =>
  markerClusters.value.map(() => ({
    isAnimating: false,
    scale: 1,
    opacity: 0.6,
    material: new MeshBasicMaterial({
      color: new Color("rgb(255, 255, 255)"),
      transparent: true,
      opacity: 0.6,
      blending: AdditiveBlending,
    }),
  })),
);

// --- Capital cities (geographic reference) ---
const CAPITALS: { name: string; lat: number; lng: number }[] = [
  { name: "Washington D.C.", lat: 38.9, lng: -77.04 },
  { name: "London", lat: 51.51, lng: -0.13 },
  { name: "Paris", lat: 48.86, lng: 2.35 },
  { name: "Berlin", lat: 52.52, lng: 13.41 },
  { name: "Tokyo", lat: 35.68, lng: 139.69 },
  { name: "Canberra", lat: -35.28, lng: 149.13 },
  { name: "Brasília", lat: -15.79, lng: -47.88 },
  { name: "Moscow", lat: 55.76, lng: 37.62 },
  { name: "Beijing", lat: 39.9, lng: 116.4 },
  { name: "New Delhi", lat: 28.61, lng: 77.21 },
  { name: "Cairo", lat: 30.04, lng: 31.24 },
  { name: "Pretoria", lat: -25.75, lng: 28.19 },
  { name: "Buenos Aires", lat: -34.6, lng: -58.38 },
  { name: "Ottawa", lat: 45.42, lng: -75.7 },
  { name: "Rome", lat: 41.9, lng: 12.5 },
  { name: "Madrid", lat: 40.42, lng: -3.7 },
  { name: "Seoul", lat: 37.57, lng: 126.98 },
  { name: "Bangkok", lat: 13.76, lng: 100.5 },
  { name: "Nairobi", lat: -1.29, lng: 36.82 },
  { name: "Mexico City", lat: 19.43, lng: -99.13 },
];

const cityRadius = GLOBE_RADIUS + GLOBE_RADIUS * 0.022;
const cityMarkerGeometry = new SphereGeometry(1.2, 12, 12);
const cityMarkerMaterial = new MeshBasicMaterial({
  color: new Color("rgb(255, 255, 255)"),
  transparent: true,
  opacity: 0.35,
});

// --- Label sprites ---
function createLabelTexture(
  text: string,
  color = "white",
  fontSize = 72,
  fontWeight = "600",
): CanvasTexture {
  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d")!;
  canvas.width = 512;
  canvas.height = 128;

  ctx.font = `${fontWeight} ${fontSize}px sans-serif`;
  ctx.shadowColor = "rgba(0, 0, 0, 1)";
  ctx.shadowBlur = 10;
  ctx.fillStyle = color;
  ctx.textBaseline = "middle";
  ctx.fillText(text, 4, 68);
  ctx.fillText(text, 4, 68);

  const tex = new CanvasTexture(canvas);
  tex.minFilter = LinearFilter;
  return tex;
}

const labelData = computed(() =>
  markerClusters.value.map((cluster) => {
    const label =
      cluster.members.length === 1
        ? cluster.members[0].username || "Unknown"
        : `${cluster.members.length} members`;
    const tex = createLabelTexture(label, "rgb(143, 216, 216)");
    const mat = new SpriteMaterial({
      map: tex,
      depthTest: false,
      transparent: true,
    });
    const dir = new Vector3(...cluster.position).normalize();
    const pos: [number, number, number] = [
      cluster.position[0] + dir.x * 5,
      cluster.position[1] + dir.y * 5 + 4,
      cluster.position[2] + dir.z * 5,
    ];
    return { id: cluster.id, material: mat, position: pos };
  }),
);

// --- City label data ---
const cityLabelData = CAPITALS.map((city) => {
  const position = toSphereCoords(city.lat, city.lng, cityRadius);
  const tex = createLabelTexture(city.name, "rgba(255, 255, 255, 0.6)", 48, "300");
  const mat = new SpriteMaterial({
    map: tex,
    depthTest: false,
    transparent: true,
    opacity: 0.7,
  });
  const dir = new Vector3(...position).normalize();
  const labelPos: [number, number, number] = [
    position[0] + dir.x * 3,
    position[1] + dir.y * 3 + 2,
    position[2] + dir.z * 3,
  ];
  return { name: city.name, position, labelPos, material: mat };
});

// --- Glow mesh refs for scale animation ---
const glowMeshRefs = ref<Record<string, any>>({});

function setGlowRef(id: string | undefined, el: any) {
  if (id && el) {
    glowMeshRefs.value[id] = el;
  }
}

// --- Animation loop ---
let rafId: number;

function animate() {
  // Animate marker glow
  const states = glowStates.value;
  const meshRefs = glowMeshRefs.value;

  for (let i = 0; i < states.length; i++) {
    const state = states[i];
    const markerId = markerClusters.value[i]?.id;
    const mesh = markerId ? meshRefs[markerId] : null;

    if (!state.isAnimating) {
      if (Math.random() > 0.99) {
        state.isAnimating = true;
      }
    } else {
      state.scale += 0.025;
      state.opacity -= 0.005;
      state.material.opacity = state.opacity;

      if (mesh) {
        mesh.scale.set(state.scale, state.scale, state.scale);
      }

      if (state.scale >= 4) {
        state.scale = 1;
        state.opacity = 0.6;
        state.material.opacity = 0.6;
        state.isAnimating = false;
        if (mesh) {
          mesh.scale.set(1, 1, 1);
        }
      }
    }
  }

  // Traveling dots along arcs
  const arcs = arcData.value;
  if (arcs.length > 0) {
    for (let i = 0; i < MAX_DOTS; i++) {
      const dot = travelingDots[i];

      if (!dot.path) {
        if (Math.random() > 0.99) {
          const arcIdx = Math.floor(Math.random() * arcs.length);
          dot.path = arcs[arcIdx].curve.getPoints(200);
          dot.pathIndex = 0;
        }
        dotsArray[i * 3] = 99999;
        dotsArray[i * 3 + 1] = 99999;
        dotsArray[i * 3 + 2] = 99999;
        continue;
      }

      if (dot.pathIndex < dot.path.length - 1) {
        const pos = dot.path[dot.pathIndex];
        dotsArray[i * 3] = pos.x;
        dotsArray[i * 3 + 1] = pos.y;
        dotsArray[i * 3 + 2] = pos.z;
        dot.pathIndex++;
      } else {
        dot.path = null;
        dotsArray[i * 3] = 99999;
        dotsArray[i * 3 + 1] = 99999;
        dotsArray[i * 3 + 2] = 99999;
      }
    }

    const attr =
      dotsGeometry.getAttribute("position") as Float32BufferAttribute;
    attr.needsUpdate = true;
  }

  rafId = requestAnimationFrame(animate);
}

onMounted(() => {
  rafId = requestAnimationFrame(animate);
});

onUnmounted(() => {
  cancelAnimationFrame(rafId);
});
</script>

<template>
  <div class="members-worldmap">
    <TresCanvas
      :clear-color="0x000000"
      :clear-alpha="0"
      :shadows="false"
      :dpr="dpr"
      :power-preference="powerPreference"
      :alpha="true"
    >
      <TresPerspectiveCamera
        :position="[0, 0, GLOBE_RADIUS * 2.85]"
        :args="[60, 1, 0.1, 10000]"
      />
      <OrbitControls
        enable-damping
        :damping-factor="0.05"
        :rotate-speed="0.8"
        :enable-zoom="true"
        :zoom-speed="0.5"
        :min-distance="GLOBE_RADIUS * 1.2"
        :max-distance="GLOBE_RADIUS * 4"
        :enable-pan="false"
        make-default
      />

      <!-- Globe group -->
      <TresGroup :rotation-y="-Math.PI / 2">
        <!-- Globe with earth texture + rim glow -->
        <TresMesh :geometry="globeGeometry" :material="globeMaterial" />

        <!-- Member markers (clustered) -->
        <TresGroup v-for="(cluster, idx) in markerClusters" :key="cluster.id">
          <TresMesh
            :position="cluster.position"
            :geometry="markerGeometry"
            :material="markerMaterial"
            :scale="[clusterScale(cluster.members.length), clusterScale(cluster.members.length), clusterScale(cluster.members.length)]"
          />
          <TresMesh
            :ref="(el: any) => setGlowRef(cluster.id, el)"
            :position="cluster.position"
            :geometry="markerGeometry"
            :material="glowStates[idx]?.material"
          />
        </TresGroup>

        <!-- Username labels -->
        <TresSprite
          v-for="item in labelData"
          :key="item.id"
          :position="item.position"
          :material="item.material"
          :scale="[60, 15, 1]"
        />

        <!-- Capital city markers -->
        <TresGroup v-for="city in cityLabelData" :key="city.name">
          <TresMesh
            :position="city.position"
            :geometry="cityMarkerGeometry"
            :material="cityMarkerMaterial"
          />
          <TresSprite
            :position="city.labelPos"
            :material="city.material"
            :scale="[45, 11, 1]"
          />
        </TresGroup>

        <!-- Connection arcs -->
        <TresMesh
          v-for="(arc, i) in arcData"
          :key="i"
          :geometry="arc.geometry"
          :material="arcMaterial"
        />

        <!-- Traveling dots -->
        <TresPoints :geometry="dotsGeometry" :material="dotsMaterial" />
      </TresGroup>

    </TresCanvas>
  </div>
</template>

<style lang="scss" scoped>
.members-worldmap {
  position: relative;
  height: calc(100vh - 300px);
  min-height: 400px;
  border-radius: 8px;
  overflow: hidden;
}
</style>
