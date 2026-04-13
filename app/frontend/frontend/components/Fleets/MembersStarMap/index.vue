<script lang="ts">
export default {
  name: "MembersStarMap",
};
</script>

<script lang="ts" setup>
import { MeshBasicMaterial, Color, Vector3 } from "three";
import { LineSegmentsGeometry } from "three/examples/jsm/lines/LineSegmentsGeometry.js";
import { LineSegments2 } from "three/examples/jsm/lines/LineSegments2.js";
import { LineMaterial } from "three/examples/jsm/lines/LineMaterial.js";
import { TresCanvas } from "@tresjs/core";
import { OrbitControls, Html } from "@tresjs/cientos";
import { useMobile } from "@/shared/composables/useMobile";
import type { FleetMember } from "@/services/fyApi";
import {
  starSystems,
  jumpTunnels,
  ACTIVE_SYSTEMS,
  type StarSystem,
} from "@/frontend/data/starmap";

type Props = {
  members: FleetMember[];
};

const props = defineProps<Props>();

const mobile = useMobile();

const dpr = computed(() =>
  mobile.value
    ? Math.min(window.devicePixelRatio, 1.5)
    : window.devicePixelRatio,
);

const powerPreference = computed<WebGLPowerPreference>(() =>
  mobile.value ? "low-power" : "default",
);

// --- Coordinate scaling ---
const SCALE = 0.5;

const systemPosition = (system: StarSystem): [number, number, number] => [
  system.positionX * SCALE,
  system.positionY * SCALE,
  system.positionZ * SCALE,
];

const labelOffset = (system: StarSystem): [number, number, number] => [
  system.positionX * SCALE,
  system.positionY * SCALE + (ACTIVE_SYSTEMS.has(system.code) ? 1.2 : 0.6),
  system.positionZ * SCALE,
];

// Build a lookup map
const systemByCode = new Map(starSystems.map((s) => [s.code, s]));

// --- Fat line helpers ---
const buildLineSegments = (
  positions: number[],
  color: string,
  opacity: number,
  linewidth: number,
): LineSegments2 => {
  const geo = new LineSegmentsGeometry();
  geo.setPositions(positions);
  const mat = new LineMaterial({
    color: new Color(color).getHex(),
    linewidth,
    transparent: true,
    opacity,
    worldUnits: true,
    depthTest: true,
  });
  const line = new LineSegments2(geo, mat);
  line.computeLineDistances();
  return line;
};

// --- Jump route line objects ---
const routeLines = computed(() => {
  const positions: number[] = [];
  for (const tunnel of jumpTunnels) {
    const fromSys = systemByCode.get(tunnel.from);
    const toSys = systemByCode.get(tunnel.to);
    if (!fromSys || !toSys) continue;
    const [fx, fy, fz] = systemPosition(fromSys);
    const [tx, ty, tz] = systemPosition(toSys);
    positions.push(fx, fy, fz, tx, ty, tz);
  }
  return buildLineSegments(positions, "#4a4a5a", 0.25, 0.08);
});

// --- Highlight routes (connecting active systems) ---
const activeRouteLines = computed(() => {
  const positions: number[] = [];
  for (const tunnel of jumpTunnels) {
    if (!ACTIVE_SYSTEMS.has(tunnel.from) || !ACTIVE_SYSTEMS.has(tunnel.to))
      continue;
    const fromSys = systemByCode.get(tunnel.from);
    const toSys = systemByCode.get(tunnel.to);
    if (!fromSys || !toSys) continue;
    const [fx, fy, fz] = systemPosition(fromSys);
    const [tx, ty, tz] = systemPosition(toSys);
    positions.push(fx, fy, fz, tx, ty, tz);
  }
  return buildLineSegments(positions, "#428bca", 0.9, 0.15);
});

// Dimmed system nodes: muted purple-grey (rendered on top of lines)
const dimmedSystemMaterial = new MeshBasicMaterial({
  color: new Color("#6a5a7a"),
  transparent: true,
  opacity: 0.5,
  depthTest: false,
});

// Active system nodes: primary blue (rendered on top of lines)
const activeSystemMaterial = new MeshBasicMaterial({
  color: new Color("#428bca"),
  transparent: true,
  opacity: 0.9,
  depthTest: false,
});

const activeSystemGlowMaterial = new MeshBasicMaterial({
  color: new Color("#428bca"),
  transparent: true,
  opacity: 0.25,
  depthTest: false,
});

// Member markers: green
const memberMarkerMaterial = new MeshBasicMaterial({
  color: new Color("#42b883"),
  transparent: true,
  opacity: 0.9,
});

const memberMarkerGlowMaterial = new MeshBasicMaterial({
  color: new Color("#42b883"),
  transparent: true,
  opacity: 0.3,
});

// --- Members grouped by system ---
const membersBySystem = computed(() => {
  const map = new Map<string, FleetMember[]>();
  for (const member of props.members) {
    if (!member.currentSystemCode) continue;
    const existing = map.get(member.currentSystemCode) || [];
    existing.push(member);
    map.set(member.currentSystemCode, existing);
  }
  return map;
});

// --- Compute member marker positions (offset around system node) ---
const memberMarkers = computed(() => {
  const markers: {
    member: FleetMember;
    position: [number, number, number];
  }[] = [];
  for (const [code, members] of membersBySystem.value) {
    const system = systemByCode.get(code);
    if (!system) continue;
    const [sx, sy, sz] = systemPosition(system);
    const count = members.length;
    for (let i = 0; i < count; i++) {
      const angle = (2 * Math.PI * i) / Math.max(count, 1);
      const offset = 0.8;
      markers.push({
        member: members[i],
        position: [
          sx + Math.cos(angle) * offset,
          sy + Math.sin(angle) * offset,
          sz,
        ],
      });
    }
  }
  return markers;
});

// --- Camera position (centered on the active systems) ---
const cameraTarget = computed(() => {
  const activeSystems = starSystems.filter((s) => ACTIVE_SYSTEMS.has(s.code));
  if (activeSystems.length === 0) return new Vector3(0, 0, 0);
  const avg = activeSystems.reduce(
    (acc, s) => {
      const [x, y, z] = systemPosition(s);
      return [acc[0] + x, acc[1] + y, acc[2] + z];
    },
    [0, 0, 0],
  );
  const n = activeSystems.length;
  return new Vector3(avg[0] / n, avg[1] / n, avg[2] / n);
});

const cameraPosition = computed(() => {
  const t = cameraTarget.value;
  return [t.x, t.y + 5, t.z + 30] as [number, number, number];
});

// --- Tooltip ---
const hoveredItem = ref<{ label: string } | null>(null);
const tooltipPos = ref({ x: 0, y: 0 });

const onMemberEnter = (member: FleetMember) => {
  hoveredItem.value = { label: member.username };
};

const onItemLeave = () => {
  hoveredItem.value = null;
};

const onPointerMove = (event: PointerEvent) => {
  tooltipPos.value = { x: event.clientX, y: event.clientY };
};
</script>

<template>
  <div class="members-starmap" @pointermove="onPointerMove">
    <TresCanvas
      :clear-alpha="0"
      :shadows="false"
      :dpr="dpr"
      :power-preference="powerPreference"
      alpha
    >
      <TresPerspectiveCamera
        :position="cameraPosition"
        :args="[60, 1, 0.1, 500]"
      />
      <OrbitControls
        auto-rotate
        :auto-rotate-speed="0.3"
        enable-rotate
        :enable-zoom="true"
        :zoom-speed="0.5"
        :min-distance="10"
        :max-distance="120"
        enable-damping
        :damping-factor="0.05"
        :enable-pan="true"
        :target="cameraTarget"
        make-default
      />

      <!-- Jump routes (dimmed) -->
      <primitive :object="routeLines" />

      <!-- Active routes (highlighted) -->
      <primitive :object="activeRouteLines" />

      <!-- Star systems -->
      <TresGroup v-for="system in starSystems" :key="system.code">
        <!-- System node -->
        <TresMesh
          :position="systemPosition(system)"
          :material="
            ACTIVE_SYSTEMS.has(system.code)
              ? activeSystemMaterial
              : dimmedSystemMaterial
          "
          :render-order="1"
        >
          <TresSphereGeometry
            :args="[ACTIVE_SYSTEMS.has(system.code) ? 0.4 : 0.2, 16, 16]"
          />
        </TresMesh>
        <!-- Glow for active systems -->
        <TresMesh
          v-if="ACTIVE_SYSTEMS.has(system.code)"
          :position="systemPosition(system)"
          :material="activeSystemGlowMaterial"
        >
          <TresSphereGeometry :args="[0.7, 16, 16]" />
        </TresMesh>
        <!-- System label -->
        <Html :position="labelOffset(system)" center>
          <span
            :class="[
              'system-label',
              ACTIVE_SYSTEMS.has(system.code)
                ? 'system-label-active'
                : 'system-label-dimmed',
            ]"
          >
            {{ system.name }}
          </span>
        </Html>
      </TresGroup>

      <!-- Member markers -->
      <TresGroup v-for="item in memberMarkers" :key="item.member.id">
        <TresMesh
          :position="item.position"
          :material="memberMarkerGlowMaterial"
          @pointer-enter="() => onMemberEnter(item.member)"
          @pointer-leave="onItemLeave"
        >
          <TresSphereGeometry :args="[0.35, 16, 16]" />
        </TresMesh>
        <TresMesh :position="item.position" :material="memberMarkerMaterial">
          <TresSphereGeometry :args="[0.18, 16, 16]" />
        </TresMesh>
      </TresGroup>
    </TresCanvas>

    <!-- Tooltip overlay -->
    <div
      v-if="hoveredItem"
      class="starmap-tooltip"
      :style="{
        left: `${tooltipPos.x + 12}px`,
        top: `${tooltipPos.y - 20}px`,
      }"
    >
      {{ hoveredItem.label }}
    </div>

    <!-- Legend -->
    <div class="starmap-legend">
      <div class="legend-item">
        <span class="legend-dot legend-dot-active" />
        Active System
      </div>
      <div class="legend-item">
        <span class="legend-dot legend-dot-dimmed" />
        Known System
      </div>
      <div class="legend-item">
        <span class="legend-dot legend-dot-member" />
        Fleet Member
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.members-starmap {
  position: relative;
  height: calc(100vh - 300px);
  min-height: 400px;
  border-radius: 8px;
  overflow: hidden;
}

.starmap-tooltip {
  position: fixed;
  padding: 4px 10px;
  background: rgba(10, 22, 40, 0.9);
  color: #428bca;
  border: 1px solid #428bca;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 600;
  pointer-events: none;
  z-index: 10;
  white-space: nowrap;
}

.starmap-legend {
  position: absolute;
  bottom: 16px;
  left: 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 10px 14px;
  background: rgba(10, 22, 40, 0.85);
  border: 1px solid rgba(66, 139, 202, 0.3);
  border-radius: 6px;
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.7);
  pointer-events: none;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.legend-dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 50%;

  &-active {
    background: #428bca;
    box-shadow: 0 0 6px rgba(66, 139, 202, 0.6);
  }

  &-dimmed {
    background: #6a5a7a;
  }

  &-member {
    background: #42b883;
    box-shadow: 0 0 6px rgba(66, 184, 131, 0.6);
  }
}

:deep(.system-label) {
  font-size: 10px;
  font-weight: 500;
  white-space: nowrap;
  pointer-events: none;
  text-shadow: 0 0 4px rgba(0, 0, 0, 0.8);
}

:deep(.system-label-active) {
  color: #428bca;
  font-size: 12px;
  font-weight: 700;
  text-shadow:
    0 0 6px rgba(66, 139, 202, 0.5),
    0 0 3px rgba(0, 0, 0, 0.9);
}

:deep(.system-label-dimmed) {
  color: rgba(180, 170, 200, 0.6);
}
</style>
