<script lang="ts">
export default {
  name: "MembersStarMap",
};
</script>

<script lang="ts" setup>
import { MeshBasicMaterial, Color, Vector2, Vector3 } from "three";
import { LineSegmentsGeometry } from "three/examples/jsm/lines/LineSegmentsGeometry.js";
import { LineSegments2 } from "three/examples/jsm/lines/LineSegments2.js";
import { LineMaterial } from "three/examples/jsm/lines/LineMaterial.js";
import { TresCanvas, useLoop } from "@tresjs/core";
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

// --- Track all LineMaterials so we can update their resolution ---
const lineMaterials: LineMaterial[] = [];

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
    worldUnits: false,
    depthTest: true,
    polygonOffset: true,
    polygonOffsetFactor: 1,
    polygonOffsetUnits: 1,
  });
  lineMaterials.push(mat);
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
  return buildLineSegments(positions, "#4a5568", 0.35, 2);
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
  return buildLineSegments(positions, "#5aafd4", 0.85, 3);
});

// Dimmed system nodes: muted purple-grey
const dimmedSystemMaterial = new MeshBasicMaterial({
  color: new Color("#6a5a7a"),
});

// Active system nodes: primary blue
const activeSystemMaterial = new MeshBasicMaterial({
  color: new Color("#428bca"),
});

const activeSystemGlowMaterial = new MeshBasicMaterial({
  color: new Color("#428bca"),
  transparent: true,
  opacity: 0.25,
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

// --- System member badges (one per system that has members) ---
const systemMemberBadges = computed(() => {
  const badges: {
    systemCode: string;
    members: FleetMember[];
    position: [number, number, number];
  }[] = [];
  for (const [code, members] of membersBySystem.value) {
    const system = systemByCode.get(code);
    if (!system) continue;
    const [sx, sy, sz] = systemPosition(system);
    badges.push({
      systemCode: code,
      members,
      position: [sx, sy - (ACTIVE_SYSTEMS.has(code) ? 1.4 : 0.8), sz],
    });
  }
  return badges;
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

// --- Inner component to access the render loop for resolution updates ---
const resolutionVec = new Vector2();
const ResolutionUpdater = defineComponent({
  setup() {
    const { onBeforeRender } = useLoop();
    onBeforeRender(({ renderer }) => {
      if (!renderer) return;
      renderer.getSize(resolutionVec);
      for (const mat of lineMaterials) {
        mat.resolution.set(resolutionVec.x, resolutionVec.y);
      }
    });
    return () => null;
  },
});
</script>

<template>
  <div class="members-starmap">
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

      <!-- Resolution updater for fat lines -->
      <ResolutionUpdater />

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
        <Html :position="labelOffset(system)" center :z-index-range="[1, 10]">
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

      <!-- Member badges per system -->
      <TresGroup v-for="badge in systemMemberBadges" :key="badge.systemCode">
        <Html :position="badge.position" center :z-index-range="[50, 100]">
          <div class="member-badge">
            <span class="member-badge-count">{{ badge.members.length }}</span>
            <div class="member-badge-names">
              <span
                v-for="m in badge.members"
                :key="m.id"
                class="member-badge-name"
              >
                {{ m.username }}
              </span>
            </div>
          </div>
        </Html>
      </TresGroup>
    </TresCanvas>

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
  user-select: none;
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
  position: relative;
  z-index: 1;
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

:deep(.member-badge) {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  pointer-events: auto;
  cursor: default;
  position: relative;
  z-index: 50;

  .member-badge-count {
    display: flex;
    align-items: center;
    justify-content: center;
    min-width: 22px;
    height: 22px;
    padding: 0 6px;
    border-radius: 11px;
    background: #42b883;
    color: #0a1628;
    font-size: 11px;
    font-weight: 700;
    box-shadow: 0 0 8px rgba(66, 184, 131, 0.6);
  }

  .member-badge-names {
    display: none;
    flex-direction: column;
    align-items: center;
    gap: 1px;
    padding: 6px 10px;
    background: rgba(10, 22, 40, 0.97);
    border: 1px solid rgba(66, 184, 131, 0.4);
    border-radius: 4px;
    max-height: 200px;
    overflow-y: auto;
    position: relative;
    z-index: 100;
  }

  &:hover .member-badge-names {
    display: flex;
  }

  .member-badge-name {
    color: #42b883;
    font-size: 11px;
    font-weight: 600;
    white-space: nowrap;
    text-shadow: 0 0 3px rgba(0, 0, 0, 0.8);
  }
}
</style>
