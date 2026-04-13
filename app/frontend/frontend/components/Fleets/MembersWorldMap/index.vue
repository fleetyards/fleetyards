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
  PointsMaterial,
  SpriteMaterial,
  AdditiveBlending,
  BackSide,
  Color,
  BufferGeometry,
  Float32BufferAttribute,
  QuadraticBezierCurve3,
  Vector3,
  TubeGeometry,
  CanvasTexture,
  LinearFilter,
} from "three";
import { TresCanvas } from "@tresjs/core";
import { OrbitControls } from "@tresjs/cientos";
import { useMobile } from "@/shared/composables/useMobile";
import type { FleetMember } from "@/services/fyApi";
import gridCoords from "@/frontend/data/globe-grid.json";

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
const GRID_OFFSET = GLOBE_RADIUS + GLOBE_RADIUS * 0.025;

// --- Coordinate conversion (standard geographic → 3D) ---
// +Y = north pole, XZ plane = equator
function toSphereCoords(
  lat: number,
  lng: number,
  radius: number,
): [number, number, number] {
  const latRad = (lat * Math.PI) / 180;
  const lngRad = (lng * Math.PI) / 180;
  const x = radius * Math.cos(latRad) * Math.cos(lngRad);
  const y = radius * Math.sin(latRad);
  const z = radius * Math.cos(latRad) * Math.sin(lngRad);
  return [x, y, z];
}

// --- Members ---
const membersWithLocation = computed(() =>
  props.members.filter(
    (m) => m.latitude != null && m.longitude != null,
  ),
);

const markerPositions = computed(() =>
  membersWithLocation.value.map((member) => ({
    member,
    position: toSphereCoords(
      member.latitude!,
      member.longitude!,
      MARKER_OFFSET,
    ),
  })),
);

// --- Globe (no texture, just rim glow like reference with null texture) ---
const globeGeometry = new SphereGeometry(GLOBE_RADIUS, 64, 64);

const globeMaterial = new ShaderMaterial({
  vertexShader: `
    varying vec3 vNormal;
    void main() {
      vNormal = normalize(normalMatrix * normal);
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    varying vec3 vNormal;
    void main() {
      float intensity = 1.05 - dot(vNormal, vec3(0.0, 0.0, 1.0));
      vec3 atmosphere = vec3(1.0, 1.0, 1.0) * pow(intensity, 3.0);
      gl_FragColor = vec4(atmosphere, 1.0);
    }
  `,
  blending: AdditiveBlending,
  transparent: true,
});

// --- Atmosphere (white glow, matching reference exactly) ---
const atmosphereMaterial = new ShaderMaterial({
  vertexShader: `
    varying vec3 vNormal;
    void main() {
      vNormal = normalize(normalMatrix * normal);
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    varying vec3 vNormal;
    void main() {
      float intensity = pow(0.7 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 4.0);
      gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0) * intensity;
    }
  `,
  blending: AdditiveBlending,
  side: BackSide,
  transparent: true,
});

// --- Dot grid (land-mass points from reference grid data) ---
function buildGridGeometry(radius: number): BufferGeometry {
  const positions: number[] = [];
  for (const [lat, lon] of gridCoords as [number, number][]) {
    const [x, y, z] = toSphereCoords(lat, lon, radius);
    positions.push(x, y, z);
  }
  const geo = new BufferGeometry();
  geo.setAttribute(
    "position",
    new Float32BufferAttribute(new Float32Array(positions), 3),
  );
  return geo;
}

const gridGeometry = buildGridGeometry(GRID_OFFSET);
const gridMaterial = new PointsMaterial({
  color: new Color("rgb(203, 168, 0)"),
  size: 2,
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
  const pts = markerPositions.value;
  if (pts.length < 2) return [];

  const members = membersWithLocation.value;
  const arcs: ArcEntry[] = [];

  for (let i = 0; i < members.length; i++) {
    const j = (i + 1) % members.length;
    const { start, mid, end } = getSplineCoords(
      members[i].latitude!,
      members[i].longitude!,
      members[j].latitude!,
      members[j].longitude!,
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

// --- Traveling dots along arcs (matching reference Dots class) ---
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
  arcIndex: number;
  pathIndex: number;
  path: Vector3[] | null;
  active: boolean;
}

const travelingDots: TravelingDot[] = Array.from(
  { length: MAX_DOTS },
  () => ({
    arcIndex: 0,
    pathIndex: 0,
    path: null,
    active: false,
  }),
);

// --- Marker materials ---
const markerGeometry = new SphereGeometry(2, 15, 15);

const markerMaterial = new MeshBasicMaterial({
  color: new Color("rgb(143, 216, 216)"),
  transparent: true,
  opacity: 0.8,
});

// Per-marker glow state for independent pulse animation
interface GlowState {
  isAnimating: boolean;
  scale: number;
  opacity: number;
  material: MeshBasicMaterial;
}

const glowStates = computed<GlowState[]>(() =>
  markerPositions.value.map(() => ({
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

// --- Label sprites ---
function createLabelTexture(text: string): CanvasTexture {
  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d")!;
  canvas.width = 512;
  canvas.height = 128;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.font = "300 28px sans-serif";
  ctx.fillStyle = "white";
  ctx.textBaseline = "middle";
  ctx.fillText(text, 4, 64);
  const tex = new CanvasTexture(canvas);
  tex.minFilter = LinearFilter;
  return tex;
}

const labelData = computed(() =>
  markerPositions.value.map((item) => {
    const tex = createLabelTexture(
      item.member.username || "Unknown",
    );
    const mat = new SpriteMaterial({
      map: tex,
      depthTest: false,
      transparent: true,
    });
    // Offset label slightly above marker
    const pos: [number, number, number] = [
      item.position[0],
      item.position[1] + 4,
      item.position[2],
    ];
    return { id: item.member.id, material: mat, position: pos };
  }),
);

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
  // Animate marker glow (reference: random 1% chance per frame to start pulse)
  const states = glowStates.value;
  const meshRefs = glowMeshRefs.value;

  for (let i = 0; i < states.length; i++) {
    const state = states[i];
    const markerId = markerPositions.value[i]?.member.id;
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
      clear-color="#000000"
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
        :rotate-speed="0.07"
        :enable-zoom="true"
        :enable-pan="false"
        make-default
      />

      <!-- Globe group (slow auto-rotation matching reference) -->
      <TresGroup>
        <!-- Globe sphere (rim glow only, no texture) -->
        <TresMesh :geometry="globeGeometry" :material="globeMaterial" />

        <!-- Dot grid (gold dots covering globe surface) -->
        <TresPoints :geometry="gridGeometry" :material="gridMaterial" />

        <!-- Member markers -->
        <TresGroup v-for="(item, idx) in markerPositions" :key="item.member.id">
          <!-- Marker point (teal) -->
          <TresMesh
            :position="item.position"
            :geometry="markerGeometry"
            :material="markerMaterial"
          />
          <!-- Glow (white, animated pulse) -->
          <TresMesh
            :ref="(el: any) => setGlowRef(item.member.id, el)"
            :position="item.position"
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
          :scale="[40, 20, 1]"
        />

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

      <!-- Atmosphere glow (outer halo) -->
      <TresMesh :material="atmosphereMaterial">
        <TresSphereGeometry :args="[GLOBE_RADIUS * 1.2, 64, 64]" />
      </TresMesh>
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
