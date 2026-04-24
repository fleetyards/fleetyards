<script lang="ts">
export default {
  name: "CargoGridViewer",
};
</script>

<script lang="ts" setup>
import { TresCanvas } from "@tresjs/core";
import { OrbitControls, Grid, Html } from "@tresjs/cientos";
import type { Group } from "three";
import CargoGridDragHandler from "./CargoGridDragHandler.vue";
import type { CargoHold } from "@/services/fyApi";
import {
  type ContainerRequest,
  type ShipEntry,
  SCU_UNIT,
  CONTAINER_DEFS,
  CONTAINER_COLORS,
} from "./constants";
import { BoxGeometry, EdgesGeometry, LineBasicMaterial, Color } from "three";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { humanizeHoldName } from "@/shared/utils/CargoHolds";

const { t } = useI18n();

const mobile = useMobile();

const dpr = computed(() =>
  mobile.value
    ? Math.min(window.devicePixelRatio, 1.5)
    : window.devicePixelRatio,
);

const powerPreference = computed<WebGLPowerPreference>(() =>
  mobile.value ? "low-power" : "default",
);

type Props = {
  cargoHolds: CargoHold[];
  ships?: ShipEntry[];
  containerRequests?: ContainerRequest[];
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  ships: () => [],
  containerRequests: () => [],
  compact: false,
});

const emit = defineEmits<{
  autoFill: [shipIndex: number];
  removeShip: [shipIndex: number];
}>();

const isMultiShipMode = computed(() => props.ships.length > 1);

type PlacedContainer = {
  size: number;
  position: [number, number, number];
  dimensions: [number, number, number];
  color: string;
};

type HoldLayout = {
  holdIndex: number;
  dimensions: [number, number, number];
  position: [number, number, number];
  containers: PlacedContainer[];
};

type HoldGroupLayout = {
  key: string;
  label: string;
  position: [number, number, number];
  holds: HoldLayout[];
};

type PackResult = {
  groups: HoldGroupLayout[];
  placed: Record<number, number>;
  notPlaced: Record<number, number>;
};

function getHoldGroupKey(name: string, allNames: string[]): string {
  if (!name) return name;
  for (const other of allNames) {
    if (other !== name && name.startsWith(other)) {
      const suffix = name.slice(other.length);
      // Match underscore separator (e.g. cargo_walkway) or numeric suffix (e.g. cargo2)
      if (suffix.startsWith("_") || /^\d+$/.test(suffix)) {
        return other;
      }
    }
  }
  return name;
}

// Group cargo holds by name prefix, preserving original indices
function groupCargoHolds(
  holds: CargoHold[],
): { key: string; label: string; holdIndices: number[] }[] {
  const allNames = holds.map((h) => h.name || "").filter((n) => n);

  // Pass 1: prefix matching (e.g. module_01 is prefix of module_01_walkway)
  const groupKeys: string[] = holds.map((hold, idx) => {
    const name = hold.name || "";
    if (!name) return `hold_${idx}`;
    return getHoldGroupKey(name, allNames);
  });

  // Pass 2: merge single-hold groups by stripping last name segment
  // (e.g. cargo_front_left + cargo_front_right → cargo_front)
  const keyCounts = new Map<string, number>();
  for (const key of groupKeys) {
    keyCounts.set(key, (keyCounts.get(key) || 0) + 1);
  }

  const singleKeys = new Set(
    [...keyCounts.entries()].filter(([, c]) => c === 1).map(([k]) => k),
  );

  if (singleKeys.size > 1) {
    const parentChildren = new Map<string, string[]>();
    for (const key of singleKeys) {
      const lastUnderscore = key.lastIndexOf("_");
      if (lastUnderscore > 0) {
        const parent = key.substring(0, lastUnderscore);
        if (!parentChildren.has(parent)) parentChildren.set(parent, []);
        parentChildren.get(parent)!.push(key);
      }
    }

    const mergeMap = new Map<string, string>();
    for (const [parent, children] of parentChildren) {
      if (children.length >= 2) {
        for (const child of children) mergeMap.set(child, parent);
      }
    }

    if (mergeMap.size > 0) {
      for (let i = 0; i < groupKeys.length; i++) {
        const merged = mergeMap.get(groupKeys[i]);
        if (merged) groupKeys[i] = merged;
      }
    }
  }

  const allHaveOffsets = holds.every(
    (h) =>
      h.offset &&
      h.offset.x != null &&
      h.offset.y != null &&
      h.offset.z != null,
  );

  // Build groups maintaining insertion order
  const groupMap = new Map<string, number[]>();
  const groupOrder: string[] = [];

  for (let i = 0; i < holds.length; i++) {
    const key = groupKeys[i];
    if (!groupMap.has(key)) {
      groupMap.set(key, []);
      groupOrder.push(key);
    }
    groupMap.get(key)!.push(i);
  }

  // If all holds have offsets and every natural group is small (≤ 2 holds),
  // collapse into a single group so the backend fully controls the cross-group
  // layout (e.g. Hull B diamond pattern spanning 8 name-based groups).
  // Ships with larger groups (e.g. Caterpillar modules with 3 holds each)
  // keep their per-group arrangement so offsets work within each group.
  if (allHaveOffsets && holds.length > 1) {
    const maxGroupSize = Math.max(
      ...groupOrder.map((key) => groupMap.get(key)!.length),
    );

    if (maxGroupSize <= 2) {
      const commonPrefix =
        groupKeys.reduce((prefix, key) => {
          while (prefix && !key.startsWith(prefix)) {
            const lastUnderscore = prefix.lastIndexOf("_");
            prefix =
              lastUnderscore > 0 ? prefix.substring(0, lastUnderscore) : "";
          }
          return prefix;
        }, groupKeys[0]) || "cargo";

      return [
        {
          key: commonPrefix,
          label: humanizeHoldName(commonPrefix),
          holdIndices: holds.map((_, i) => i),
        },
      ];
    }
  }

  return groupOrder.map((key) => ({
    key,
    label: key.startsWith("hold_")
      ? `Hold ${key.slice(5)}`
      : humanizeHoldName(key),
    holdIndices: groupMap.get(key)!,
  }));
}

// 2D hold arrangement: find layout with minimum bounding volume
type Placement = {
  hi: number;
  ox: number;
  oy: number;
  oz: number;
  gx: number;
  gy: number;
  gz: number;
};
type ArrangeResult = {
  boundingVolume: number;
  groupWidthSCU: number;
  groupDepthSCU: number;
  groupHeightSCU: number;
  positions: {
    hi: number;
    pos: [number, number, number];
    dims: [number, number, number];
    gridX: number;
    gridY: number;
    gridZ: number;
  }[];
};

function placementsToResult(placements: Placement[]): ArrangeResult {
  let minX = Infinity,
    maxX = -Infinity,
    minY = Infinity,
    maxY = -Infinity,
    minZ = Infinity,
    maxZ = -Infinity;
  for (const p of placements) {
    minX = Math.min(minX, p.ox);
    maxX = Math.max(maxX, p.ox + p.gx);
    minY = Math.min(minY, p.oy);
    maxY = Math.max(maxY, p.oy + p.gz);
    minZ = Math.min(minZ, p.oz);
    maxZ = Math.max(maxZ, p.oz + p.gy);
  }
  const widthSCU = maxX - minX;
  const depthSCU = maxZ - minZ;
  const heightSCU = maxY - minY;

  return {
    boundingVolume: widthSCU * depthSCU * heightSCU,
    groupWidthSCU: widthSCU,
    groupDepthSCU: depthSCU,
    groupHeightSCU: heightSCU,
    positions: placements.map((p) => ({
      hi: p.hi,
      // Position hold center relative to group's left-front-bottom corner
      pos: [
        (p.ox - minX + p.gx / 2) * SCU_UNIT,
        (p.oy - minY + p.gz / 2) * SCU_UNIT,
        (p.oz - minZ + p.gy / 2) * SCU_UNIT,
      ] as [number, number, number],
      dims: [p.gx * SCU_UNIT, p.gz * SCU_UNIT, p.gy * SCU_UNIT] as [
        number,
        number,
        number,
      ],
      gridX: p.gx,
      gridY: p.gy,
      gridZ: p.gz,
    })),
  };
}

function findBestHoldArrangement(
  cargoHolds: CargoHold[],
  holdIndices: number[],
): ArrangeResult {
  type HoldDim = { hi: number; x: number; y: number; z: number };
  const dims: HoldDim[] = holdIndices.map((hi) => {
    const h = cargoHolds[hi];
    return {
      hi,
      x: Math.floor(h.dimensions.x / SCU_UNIT),
      y: Math.floor(h.dimensions.y / SCU_UNIT),
      z: Math.floor(h.dimensions.z / SCU_UNIT),
    };
  });

  // Check if all holds in this group have offsets — use manual placement
  const allHaveOffsets = holdIndices.every((hi) => {
    const h = cargoHolds[hi];
    return (
      h.offset && h.offset.x != null && h.offset.y != null && h.offset.z != null
    );
  });

  if (allHaveOffsets) {
    // Use manual offsets: offset values are in meters, convert to grid cells
    const placements: Placement[] = dims.map((d) => {
      const h = cargoHolds[d.hi];
      const rotXZ = h.rotation === 90;
      const rotXY = h.rotation === 270;
      return {
        hi: d.hi,
        ox: h.offset!.x / SCU_UNIT,
        oy: h.offset!.z / SCU_UNIT,
        oz: h.offset!.y / SCU_UNIT,
        gx: rotXZ ? d.z : rotXY ? d.y : d.x,
        gy: rotXY ? d.x : d.y,
        gz: rotXZ ? d.x : d.z,
      };
    });
    return placementsToResult(placements);
  }

  const candidates: ArrangeResult[] = [];

  // Option 1: All along X
  {
    let ox = 0;
    const pl: Placement[] = dims.map((d) => {
      const p = { hi: d.hi, ox, oy: 0, oz: 0, gx: d.x, gy: d.y, gz: d.z };
      ox += d.x;
      return p;
    });
    candidates.push(placementsToResult(pl));
  }

  // Option 2: All along Z
  {
    let oz = 0;
    const pl: Placement[] = dims.map((d) => {
      const p = { hi: d.hi, ox: 0, oy: 0, oz, gx: d.x, gy: d.y, gz: d.z };
      oz += d.y;
      return p;
    });
    candidates.push(placementsToResult(pl));
  }

  // Option 3: L-shaped — pull each hold out and place it on the side
  if (dims.length >= 2) {
    for (let i = 0; i < dims.length; i++) {
      const side = dims[i];
      const main = dims
        .filter((_, j) => j !== i)
        .sort((a, b) => b.x * b.y * b.z - a.x * a.y * a.z);

      for (const mainAxis of ["x", "z"] as const) {
        let offset = 0;
        const mainPl: Placement[] = main.map((d) => {
          const p =
            mainAxis === "x"
              ? {
                  hi: d.hi,
                  ox: offset,
                  oy: 0,
                  oz: 0,
                  gx: d.x,
                  gy: d.y,
                  gz: d.z,
                }
              : {
                  hi: d.hi,
                  ox: 0,
                  oy: 0,
                  oz: offset,
                  gx: d.x,
                  gy: d.y,
                  gz: d.z,
                };
          offset += mainAxis === "x" ? d.x : d.y;
          return p;
        });

        const mainWidth =
          mainAxis === "x"
            ? main.reduce((s, d) => s + d.x, 0)
            : Math.max(...main.map((d) => d.x));
        const mainDepth =
          mainAxis === "z"
            ? main.reduce((s, d) => s + d.y, 0)
            : Math.max(...main.map((d) => d.y));

        // Side hold on +X edge
        candidates.push(
          placementsToResult([
            ...mainPl,
            {
              hi: side.hi,
              ox: mainWidth,
              oy: 0,
              oz: 0,
              gx: side.x,
              gy: side.y,
              gz: side.z,
            },
          ]),
        );

        // Side hold on +Z edge
        candidates.push(
          placementsToResult([
            ...mainPl,
            {
              hi: side.hi,
              ox: 0,
              oy: 0,
              oz: mainDepth,
              gx: side.x,
              gy: side.y,
              gz: side.z,
            },
          ]),
        );
      }
    }
  }

  return candidates.reduce((best, c) =>
    c.boundingVolume < best.boundingVolume ? c : best,
  );
}

const isPreviewMode = computed(
  () =>
    !isMultiShipMode.value &&
    !props.cargoHolds?.length &&
    props.containerRequests.length > 0,
);

// Preview layout: render containers in a row without cargo holds
const previewContainers = computed<PlacedContainer[]>(() => {
  if (!isPreviewMode.value) return [];

  const containers: PlacedContainer[] = [];
  let offsetX = 0;

  for (const req of props.containerRequests) {
    const def = CONTAINER_DEFS.find((d) => d.size === req.size);
    if (!def) continue;

    for (let i = 0; i < req.quantity; i++) {
      const dims: [number, number, number] = [
        def.x * SCU_UNIT,
        def.z * SCU_UNIT,
        def.y * SCU_UNIT,
      ];

      containers.push({
        size: def.size,
        position: [offsetX + dims[0] / 2, dims[1] / 2, 0],
        dimensions: dims,
        color: CONTAINER_COLORS[def.size] || "#ffffff",
      });

      offsetX += dims[0] + 0.15;
    }
  }

  // Center all containers
  if (containers.length > 0) {
    const totalWidth = offsetX - 0.15;
    for (const c of containers) {
      c.position[0] -= totalWidth / 2;
    }
  }

  return containers;
});

const previewGeometry = computed(() => {
  if (!isPreviewMode.value || previewContainers.value.length === 0) return null;

  let maxX = 0;
  let maxY = 0;
  let maxZ = 0;

  for (const c of previewContainers.value) {
    maxX = Math.max(maxX, Math.abs(c.position[0]) + c.dimensions[0] / 2);
    maxY = Math.max(maxY, c.position[1] + c.dimensions[1] / 2);
    maxZ = Math.max(maxZ, Math.abs(c.position[2]) + c.dimensions[2] / 2);
  }

  return {
    totalWidth: maxX * 2,
    maxY: maxY,
    maxZ: maxZ * 2,
  };
});

const previewTotalSCU = computed(() => {
  let total = 0;
  for (const req of props.containerRequests) {
    total += req.size * req.quantity;
  }
  return total;
});

const packResult = computed<PackResult>(() => {
  if (!props.cargoHolds?.length) {
    return { groups: [], placed: {}, notPlaced: {} };
  }

  // Build a list of individual containers to place (largest first)
  const containersToPlace: number[] = [];
  for (const req of props.containerRequests) {
    for (let i = 0; i < req.quantity; i++) {
      containersToPlace.push(req.size);
    }
  }
  containersToPlace.sort((a, b) => b - a);

  const holdGroups = groupCargoHolds(props.cargoHolds);

  // Position groups along X, holds tiled within group to minimize bounding volume
  const groupGapSCU = 2; // 2 SCU gap between groups
  let groupOffsetX = 0; // in SCU units

  const groups: HoldGroupLayout[] = [];
  const holdGridsByIndex: (HoldGrid | null)[] = new Array(
    props.cargoHolds.length,
  ).fill(null);
  const layoutsByIndex: (HoldLayout | null)[] = new Array(
    props.cargoHolds.length,
  ).fill(null);

  const placed: Record<number, number> = {};
  const notPlaced: Record<number, number> = {};

  // Pre-calculate group layouts with optimal 2D arrangement
  const groupInfos: {
    arrangement: ArrangeResult;
    group: (typeof holdGroups)[number];
  }[] = [];

  let totalSceneWidthSCU = 0;
  for (const group of holdGroups) {
    const arrangement = findBestHoldArrangement(
      props.cargoHolds,
      group.holdIndices,
    );
    groupInfos.push({ arrangement, group });
    totalSceneWidthSCU += arrangement.groupWidthSCU;
  }
  totalSceneWidthSCU += (holdGroups.length - 1) * groupGapSCU;
  // Use Math.floor so hold edges land on integer SCU grid lines
  const sceneOffsetX = -Math.floor(totalSceneWidthSCU / 2);

  for (const { arrangement, group } of groupInfos) {
    const zOffsetSCU = -Math.floor(arrangement.groupDepthSCU / 2);
    const groupPos: [number, number, number] = [
      (sceneOffsetX + groupOffsetX) * SCU_UNIT,
      0,
      zOffsetSCU * SCU_UNIT,
    ];
    groupOffsetX += arrangement.groupWidthSCU + groupGapSCU;

    const holdLayouts: HoldLayout[] = [];

    for (const p of arrangement.positions) {
      const { hi, pos: holdPos, dims: dims3d, gridX, gridY, gridZ } = p;

      const hg: HoldGrid = {
        hold: props.cargoHolds[hi],
        holdPosition: holdPos,
        gridX,
        gridY,
        gridZ,
        occupied: new Uint8Array(gridX * gridY * gridZ),
      };
      holdGridsByIndex[hi] = hg;

      const layout: HoldLayout = {
        holdIndex: hi,
        dimensions: dims3d,
        position: holdPos,
        containers: [],
      };
      layoutsByIndex[hi] = layout;
      holdLayouts.push(layout);
    }

    groups.push({
      key: group.key,
      label: group.label,
      position: groupPos,
      holds: holdLayouts,
    });
  }

  // Sort hold indices by volume (ascending) so containers go into smallest fitting hold first
  const holdIndicesByVolume = holdGridsByIndex
    .map((hg, hi) => ({ hi, volume: hg ? hg.hold.capacity : 0 }))
    .filter((h) => holdGridsByIndex[h.hi] !== null)
    .sort((a, b) => a.volume - b.volume)
    .map((h) => h.hi);

  // Pack containers across all holds (largest container first, smallest hold first)
  for (const containerSize of containersToPlace) {
    const def = CONTAINER_DEFS.find((d) => d.size === containerSize);
    if (!def) {
      notPlaced[containerSize] = (notPlaced[containerSize] || 0) + 1;
      continue;
    }

    let wasPlaced = false;

    for (const hi of holdIndicesByVolume) {
      const hg = holdGridsByIndex[hi];
      const layout = layoutsByIndex[hi];
      if (!hg || !layout) continue;

      const maxSize = hg.hold.maxContainerSize?.size || 32;
      if (def.size > maxSize) continue;

      const result = tryPlaceOne(def, hg, layout);
      if (result) {
        wasPlaced = true;
        placed[containerSize] = (placed[containerSize] || 0) + 1;
        break;
      }
    }

    if (!wasPlaced) {
      notPlaced[containerSize] = (notPlaced[containerSize] || 0) + 1;
    }
  }

  return { groups, placed, notPlaced };
});

type HoldGrid = {
  hold: CargoHold;
  holdPosition: [number, number, number];
  gridX: number;
  gridY: number;
  gridZ: number;
  occupied: Uint8Array;
};

function tryPlaceOne(
  def: (typeof CONTAINER_DEFS)[number],
  hg: HoldGrid,
  layout: HoldLayout,
): boolean {
  const { gridX, gridY, gridZ, occupied, hold } = hg;

  const idx = (x: number, y: number, z: number) =>
    x + y * gridX + z * gridX * gridY;

  // Only rotate horizontally (swap x and y), z (height) stays fixed
  const orientations = [
    { cx: def.x, cy: def.y, cz: def.z },
    { cx: def.y, cy: def.x, cz: def.z },
  ];

  for (const orient of orientations) {
    if (orient.cx > gridX || orient.cy > gridY || orient.cz > gridZ) continue;

    for (let gz = 0; gz <= gridZ - orient.cz; gz++) {
      for (let gy = 0; gy <= gridY - orient.cy; gy++) {
        for (let gx = 0; gx <= gridX - orient.cx; gx++) {
          let fits = true;
          for (let dz = 0; dz < orient.cz && fits; dz++) {
            for (let dy = 0; dy < orient.cy && fits; dy++) {
              for (let dx = 0; dx < orient.cx && fits; dx++) {
                if (occupied[idx(gx + dx, gy + dy, gz + dz)]) {
                  fits = false;
                }
              }
            }
          }

          if (!fits) continue;

          // Mark occupied
          for (let dz = 0; dz < orient.cz; dz++) {
            for (let dy = 0; dy < orient.cy; dy++) {
              for (let dx = 0; dx < orient.cx; dx++) {
                occupied[idx(gx + dx, gy + dy, gz + dz)] = 1;
              }
            }
          }

          const rotXZ = hold.rotation === 90;
          const rotXY = hold.rotation === 270;
          const cargoX = rotXZ
            ? hold.dimensions.z
            : rotXY
              ? hold.dimensions.y
              : hold.dimensions.x;
          const cargoY = rotXY ? hold.dimensions.x : hold.dimensions.y;
          const cargoZ = rotXZ ? hold.dimensions.x : hold.dimensions.z;

          // Container dims in cargo space
          const cDimsC: [number, number, number] = [
            orient.cx * SCU_UNIT,
            orient.cy * SCU_UNIT,
            orient.cz * SCU_UNIT,
          ];

          // Container center in cargo space (relative to hold origin)
          const cPosC: [number, number, number] = [
            gx * SCU_UNIT + cDimsC[0] / 2 - cargoX / 2,
            gy * SCU_UNIT + cDimsC[1] / 2 - cargoY / 2,
            gz * SCU_UNIT + cDimsC[2] / 2 - cargoZ / 2,
          ];

          // Convert cargo(x,y,z) -> 3D(x, z, y), relative to hold center
          const containerPos: [number, number, number] = [
            cPosC[0],
            cPosC[2],
            cPosC[1],
          ];

          const containerDims: [number, number, number] = [
            cDimsC[0],
            cDimsC[2],
            cDimsC[1],
          ];

          layout.containers.push({
            size: def.size,
            position: containerPos,
            dimensions: containerDims,
            color: CONTAINER_COLORS[def.size] || "#ffffff",
          });

          return true;
        }
      }
    }
  }

  return false;
}

const groupLayouts = computed(() => packResult.value.groups);

const packVersion = computed(() =>
  groupLayouts.value.reduce(
    (acc, g) => acc + g.holds.reduce((a, l) => a + l.containers.length, 0),
    0,
  ),
);

// Multi-ship: pack each ship independently, position side by side
type ShipPackResult = {
  shipIndex: number;
  name: string;
  color: string;
  groups: HoldGroupLayout[];
  placed: Record<number, number>;
  notPlaced: Record<number, number>;
  totalSCU: number;
  maxContainerSize: number;
  packedSCU: number;
  notPlacedSCU: number;
  sceneOffset: [number, number, number];
  // Bounding dimensions for this ship's holds (in world units)
  boundingWidth: number;
  boundingDepth: number;
  boundingHeight: number;
};

function packSingleShip(
  cargoHolds: CargoHold[],
  containerRequests: ContainerRequest[],
): PackResult {
  if (!cargoHolds.length) {
    return { groups: [], placed: {}, notPlaced: {} };
  }

  const containersToPlace: number[] = [];
  for (const req of containerRequests) {
    for (let i = 0; i < req.quantity; i++) {
      containersToPlace.push(req.size);
    }
  }
  containersToPlace.sort((a, b) => b - a);

  const holdGroups = groupCargoHolds(cargoHolds);
  const groupGapSCU = 2;
  let groupOffsetX = 0;

  const groups: HoldGroupLayout[] = [];
  const holdGridsByIndex: (HoldGrid | null)[] = new Array(
    cargoHolds.length,
  ).fill(null);
  const layoutsByIndex: (HoldLayout | null)[] = new Array(
    cargoHolds.length,
  ).fill(null);
  const placed: Record<number, number> = {};
  const notPlaced: Record<number, number> = {};

  const groupInfos: {
    arrangement: ArrangeResult;
    group: (typeof holdGroups)[number];
  }[] = [];

  for (const group of holdGroups) {
    const arrangement = findBestHoldArrangement(cargoHolds, group.holdIndices);
    groupInfos.push({ arrangement, group });
  }

  // Position hold groups starting at x=0 (left-aligned), centered on Z
  for (const { arrangement, group } of groupInfos) {
    const zOffsetSCU = -Math.floor(arrangement.groupDepthSCU / 2);
    const groupPos: [number, number, number] = [
      groupOffsetX * SCU_UNIT,
      0,
      zOffsetSCU * SCU_UNIT,
    ];
    groupOffsetX += arrangement.groupWidthSCU + groupGapSCU;

    const holdLayouts: HoldLayout[] = [];

    for (const p of arrangement.positions) {
      const { hi, pos: holdPos, dims: dims3d, gridX, gridY, gridZ } = p;
      const hg: HoldGrid = {
        hold: cargoHolds[hi],
        holdPosition: holdPos,
        gridX,
        gridY,
        gridZ,
        occupied: new Uint8Array(gridX * gridY * gridZ),
      };
      holdGridsByIndex[hi] = hg;

      const layout: HoldLayout = {
        holdIndex: hi,
        dimensions: dims3d,
        position: holdPos,
        containers: [],
      };
      layoutsByIndex[hi] = layout;
      holdLayouts.push(layout);
    }

    groups.push({
      key: group.key,
      label: group.label,
      position: groupPos,
      holds: holdLayouts,
    });
  }

  const holdIndicesByVolume = holdGridsByIndex
    .map((hg, hi) => ({ hi, volume: hg ? hg.hold.capacity : 0 }))
    .filter((h) => holdGridsByIndex[h.hi] !== null)
    .sort((a, b) => a.volume - b.volume)
    .map((h) => h.hi);

  for (const containerSize of containersToPlace) {
    const def = CONTAINER_DEFS.find((d) => d.size === containerSize);
    if (!def) {
      notPlaced[containerSize] = (notPlaced[containerSize] || 0) + 1;
      continue;
    }

    let wasPlaced = false;
    for (const hi of holdIndicesByVolume) {
      const hg = holdGridsByIndex[hi];
      const layout = layoutsByIndex[hi];
      if (!hg || !layout) continue;

      const maxSize = hg.hold.maxContainerSize?.size || 32;
      if (def.size > maxSize) continue;

      const result = tryPlaceOne(def, hg, layout);
      if (result) {
        wasPlaced = true;
        placed[containerSize] = (placed[containerSize] || 0) + 1;
        break;
      }
    }

    if (!wasPlaced) {
      notPlaced[containerSize] = (notPlaced[containerSize] || 0) + 1;
    }
  }

  return { groups, placed, notPlaced };
}

// Per-ship drag offsets (user-dragged positions)
const shipDragOffsets = ref<Map<number, [number, number, number]>>(new Map());

const multiShipPackResults = computed<ShipPackResult[]>(() => {
  if (!isMultiShipMode.value) return [];

  const results: ShipPackResult[] = [];
  const shipGapSCU = 4;
  let shipOffsetX = 0;

  // First pass: compute each ship's pack result and bounding box
  const shipInfos: {
    result: PackResult;
    widthSCU: number;
    depthSCU: number;
    heightSCU: number;
  }[] = [];

  let totalWidthSCU = 0;
  for (const ship of props.ships) {
    const result = packSingleShip(ship.cargoHolds, props.containerRequests);

    const holdGroups = groupCargoHolds(ship.cargoHolds);
    const groupGapSCU = 2;
    let widthSCU = 0;
    let maxHeightSCU = 0;
    let maxDepthSCU = 0;

    for (const group of holdGroups) {
      const arr = findBestHoldArrangement(ship.cargoHolds, group.holdIndices);
      widthSCU += arr.groupWidthSCU;
      maxHeightSCU = Math.max(maxHeightSCU, arr.groupHeightSCU);
      maxDepthSCU = Math.max(maxDepthSCU, arr.groupDepthSCU);
    }
    widthSCU += Math.max(0, holdGroups.length - 1) * groupGapSCU;

    shipInfos.push({
      result,
      widthSCU: widthSCU || 2,
      depthSCU: maxDepthSCU || 2,
      heightSCU: maxHeightSCU || 2,
    });
    totalWidthSCU += (widthSCU || 2) + shipGapSCU;
  }
  totalWidthSCU -= shipGapSCU;

  const startX = -Math.floor(totalWidthSCU / 2);

  for (let i = 0; i < props.ships.length; i++) {
    const ship = props.ships[i];
    const info = shipInfos[i];

    const sceneOffset: [number, number, number] = [
      (startX + shipOffsetX) * SCU_UNIT,
      0,
      0,
    ];

    let packedSCU = 0;
    for (const [size, count] of Object.entries(info.result.placed)) {
      packedSCU += Number(size) * count;
    }
    let notPlacedSCU = 0;
    for (const [size, count] of Object.entries(info.result.notPlaced)) {
      notPlacedSCU += Number(size) * count;
    }

    results.push({
      shipIndex: i,
      name: ship.name,
      color: ship.color,
      groups: info.result.groups,
      placed: info.result.placed,
      notPlaced: info.result.notPlaced,
      totalSCU: ship.cargoHolds.reduce((sum, h) => sum + h.capacity, 0),
      maxContainerSize: Math.max(
        ...ship.cargoHolds.map((h) => h.maxContainerSize?.size || 0),
      ),
      packedSCU,
      notPlacedSCU,
      sceneOffset,
      boundingWidth: info.widthSCU * SCU_UNIT,
      boundingDepth: info.depthSCU * SCU_UNIT,
      boundingHeight: info.heightSCU * SCU_UNIT,
    });

    shipOffsetX += info.widthSCU + shipGapSCU;
  }

  return results;
});

const multiShipPackVersion = computed(() =>
  multiShipPackResults.value.reduce(
    (acc, s) =>
      acc +
      s.groups.reduce(
        (ga, g) => ga + g.holds.reduce((a, l) => a + l.containers.length, 0),
        0,
      ),
    0,
  ),
);

const shipEdgeMaterials = computed(() =>
  props.ships.map(
    (ship) =>
      new LineBasicMaterial({ color: new Color(ship.color), linewidth: 1 }),
  ),
);

// Camera based on hold geometry only (not affected by container changes)
const holdGeometry = computed(() => {
  if (isMultiShipMode.value) {
    if (!multiShipPackResults.value.length) return null;
    let totalWidth = 0;
    let maxY = 0;
    let maxZ = 0;
    for (const s of multiShipPackResults.value) {
      totalWidth += s.boundingWidth;
      maxY = Math.max(maxY, s.boundingHeight);
      maxZ = Math.max(maxZ, s.boundingDepth);
    }
    const shipGapSCU = 4;
    totalWidth +=
      (multiShipPackResults.value.length - 1) * shipGapSCU * SCU_UNIT;
    return { totalWidth, maxY: maxY * SCU_UNIT, maxZ: maxZ * SCU_UNIT };
  }

  if (!props.cargoHolds?.length) return null;

  const holdGroups = groupCargoHolds(props.cargoHolds);
  const groupGapSCU = 2;
  let totalWidthSCU = 0;
  let maxY = 0;
  let maxZ = 0;

  for (const group of holdGroups) {
    const arr = findBestHoldArrangement(props.cargoHolds, group.holdIndices);
    totalWidthSCU += arr.groupWidthSCU;
    maxY = Math.max(maxY, arr.groupHeightSCU * SCU_UNIT);
    maxZ = Math.max(maxZ, arr.groupDepthSCU * SCU_UNIT);
  }
  totalWidthSCU += (holdGroups.length - 1) * groupGapSCU;

  const totalWidth = totalWidthSCU * SCU_UNIT;
  return { totalWidth, maxY, maxZ };
});

const sceneCenter = computed<[number, number, number]>(() => {
  const g = previewGeometry.value || holdGeometry.value;
  if (!g) return [0, 0, 0];
  return [0, g.maxY / 2, 0];
});

const cameraPosition = computed<[number, number, number]>(() => {
  const g = previewGeometry.value || holdGeometry.value;
  if (!g) return [10, 10, 10];

  // Use diagonal of bounding box for distance, with FOV-aware scaling
  const diagonal = Math.sqrt(g.totalWidth ** 2 + g.maxY ** 2 + g.maxZ ** 2);
  const distance = Math.max(diagonal * 2, 5);

  return [-distance * 0.35, distance * 0.3, distance * 0.45];
});

const holdEdgeMaterial = new LineBasicMaterial({
  color: new Color("#82dbc5"),
  linewidth: 1,
});

const containerEdgeMaterial = (color: string) =>
  new LineBasicMaterial({
    color: new Color(color),
    linewidth: 1,
  });

const createEdgesGeometry = (dims: [number, number, number]) =>
  new EdgesGeometry(new BoxGeometry(...dims));

const gridFadeDistance = computed(() => {
  const g = previewGeometry.value || holdGeometry.value;
  if (!g) return 20;
  const sceneSize = Math.max(g.totalWidth, g.maxZ);
  return sceneSize + 8 * SCU_UNIT;
});

// Stats
const totalSCU = computed(() => {
  return props.cargoHolds.reduce((sum, hold) => sum + hold.capacity, 0);
});

const maxContainerSize = computed(() => {
  return Math.max(
    ...props.cargoHolds.map((h) => h.maxContainerSize?.size || 0),
  );
});

const containerCounts = computed(() => packResult.value.placed);

const packedSCU = computed(() => {
  let total = 0;
  for (const [size, count] of Object.entries(containerCounts.value)) {
    total += Number(size) * count;
  }
  return total;
});

const notPlacedCounts = computed(() => packResult.value.notPlaced);

const hasNotPlaced = computed(() =>
  Object.values(notPlacedCounts.value).some((v) => v > 0),
);

const notPlacedSCU = computed(() => {
  let total = 0;
  for (const [size, count] of Object.entries(notPlacedCounts.value)) {
    total += Number(size) * count;
  }
  return total;
});

const canvasKey = ref(0);
const resetCamera = () => {
  canvasKey.value++;
};

// Drag support for multi-ship mode
const isDragging = ref(false);
const shipGroupRefs = ref<Map<number, Group>>(new Map());
const setShipGroupRef = (el: unknown, shipIndex: number) => {
  if (el) {
    shipGroupRefs.value.set(shipIndex, el as Group);
  } else {
    shipGroupRefs.value.delete(shipIndex);
  }
};

const shipGroupsForDrag = computed(() =>
  multiShipPackResults.value.map((s) => ({
    ref: shipGroupRefs.value.get(s.shipIndex) || null,
    shipIndex: s.shipIndex,
  })),
);

const getShipPosition = (
  shipResult: ShipPackResult,
): [number, number, number] => {
  const drag = shipDragOffsets.value.get(shipResult.shipIndex);
  if (!drag) return shipResult.sceneOffset;
  return [
    shipResult.sceneOffset[0] + drag[0],
    shipResult.sceneOffset[1] + drag[1],
    shipResult.sceneOffset[2] + drag[2],
  ];
};

const onDragStart = (_shipIndex: number) => {
  isDragging.value = true;
};

const onDragMove = (shipIndex: number, offset: [number, number, number]) => {
  shipDragOffsets.value = new Map(shipDragOffsets.value);
  shipDragOffsets.value.set(shipIndex, offset);
};

const onDragEnd = (_shipIndex: number) => {
  isDragging.value = false;
};
</script>

<template>
  <div
    class="cargo-grid-viewer"
    :class="{ 'cargo-grid-viewer--compact': compact }"
    data-test="cargo-grid-viewer"
  >
    <div
      v-if="!isMultiShipMode"
      class="cargo-grid-viewer__stats"
      data-test="cargo-grid-viewer-stats"
    >
      <template v-if="isPreviewMode">
        <div class="cargo-grid-viewer__stat">
          <span class="cargo-grid-viewer__stat-label">{{
            t("labels.cargoGridViewer.totalCargo")
          }}</span>
          <span class="cargo-grid-viewer__stat-value"
            >{{ previewTotalSCU }} SCU</span
          >
        </div>
        <div
          v-for="req in containerRequests"
          :key="`preview-stat-${req.size}`"
          class="cargo-grid-viewer__stat"
        >
          <span
            class="cargo-grid-viewer__stat-color"
            :style="{ backgroundColor: CONTAINER_COLORS[req.size] }"
          />
          <span class="cargo-grid-viewer__stat-label">{{ req.size }} SCU</span>
          <span class="cargo-grid-viewer__stat-value"
            >&times;{{ req.quantity }}</span
          >
        </div>
      </template>
      <template v-else>
        <div class="cargo-grid-viewer__stat">
          <span class="cargo-grid-viewer__stat-label">{{
            t("labels.cargoGridViewer.capacity")
          }}</span>
          <span class="cargo-grid-viewer__stat-value">{{ totalSCU }} SCU</span>
        </div>
        <div class="cargo-grid-viewer__stat">
          <span class="cargo-grid-viewer__stat-label">{{
            t("labels.cargoGridViewer.maxContainerSize")
          }}</span>
          <span class="cargo-grid-viewer__stat-value"
            >{{ maxContainerSize }} SCU</span
          >
        </div>
        <div class="cargo-grid-viewer__stat">
          <span class="cargo-grid-viewer__stat-label">{{
            t("labels.cargoGridViewer.packed")
          }}</span>
          <span class="cargo-grid-viewer__stat-value">{{ packedSCU }} SCU</span>
        </div>
        <div
          v-for="(count, size) in containerCounts"
          :key="size"
          class="cargo-grid-viewer__stat"
        >
          <span
            class="cargo-grid-viewer__stat-color"
            :style="{ backgroundColor: CONTAINER_COLORS[Number(size)] }"
          />
          <span class="cargo-grid-viewer__stat-label">{{ size }} SCU</span>
          <span class="cargo-grid-viewer__stat-value">&times;{{ count }}</span>
        </div>
        <template v-if="hasNotPlaced">
          <div class="cargo-grid-viewer__stat cargo-grid-viewer__stat--warning">
            <span class="cargo-grid-viewer__stat-label">{{
              t("labels.cargoGridViewer.didNotFit")
            }}</span>
            <span class="cargo-grid-viewer__stat-value"
              >{{ notPlacedSCU }} SCU</span
            >
          </div>
          <div
            v-for="(count, size) in notPlacedCounts"
            :key="`np-${size}`"
            class="cargo-grid-viewer__stat cargo-grid-viewer__stat--warning"
          >
            <span class="cargo-grid-viewer__stat-label">{{ size }} SCU</span>
            <span class="cargo-grid-viewer__stat-value"
              >&times;{{ count }}</span
            >
          </div>
        </template>
      </template>
    </div>

    <div class="cargo-grid-viewer__canvas">
      <Btn
        class="cargo-grid-viewer__reset"
        :size="BtnSizesEnum.SMALL"
        inline
        @click="resetCamera"
      >
        <i class="fa-light fa-crosshairs" />
      </Btn>
      <TresCanvas
        :key="canvasKey"
        :clear-alpha="0"
        :shadows="!mobile"
        :dpr="dpr"
        :power-preference="powerPreference"
        alpha
        :on-error="
          (e: Error) => console.error('CargoGridViewer render error:', e)
        "
      >
        <TresPerspectiveCamera
          :position="cameraPosition"
          :args="[45, 1, 0.1, 1000]"
        />
        <OrbitControls
          :target="sceneCenter"
          :auto-rotate="false"
          :enable-rotate="!isDragging"
          :enable-zoom="!isDragging"
          :zoom-speed="0.5"
          :enable-pan="!isDragging"
          enable-damping
          :damping-factor="0.25"
          make-default
        />

        <TresAmbientLight :intensity="mobile ? 0.7 : 0.4" />
        <TresDirectionalLight
          :position="[10, 20, 10]"
          :intensity="0.8"
          :cast-shadow="!mobile"
        />

        <!-- SCU floor grid -->
        <Grid
          :args="[10, 10]"
          :position="[0, -0.01, 0]"
          cell-color="#666666"
          :cell-size="1.25"
          :cell-thickness="1.5"
          section-color="#555555"
          :section-size="3.75"
          :section-thickness="1.5"
          :infinite-grid="true"
          :fade-from="0"
          :fade-distance="gridFadeDistance"
          :fade-strength="2"
        />

        <!-- Preview mode: containers without holds -->
        <template v-if="isPreviewMode">
          <TresGroup
            v-for="(container, cIdx) in previewContainers"
            :key="`preview-${cIdx}`"
          >
            <TresMesh :position="container.position">
              <TresBoxGeometry :args="container.dimensions" />
              <TresMeshStandardMaterial
                :color="container.color"
                :transparent="true"
                :opacity="0.6"
              />
            </TresMesh>
            <TresLineSegments
              :position="container.position"
              :geometry="createEdgesGeometry(container.dimensions)"
              :material="containerEdgeMaterial(container.color)"
            />
          </TresGroup>
        </template>

        <!-- Drag handler for multi-ship mode -->
        <CargoGridDragHandler
          v-if="isMultiShipMode"
          :ship-groups="shipGroupsForDrag"
          :enabled="isMultiShipMode"
          @drag-start="onDragStart"
          @drag-move="onDragMove"
          @drag-end="onDragEnd"
        />

        <!-- Multi-ship mode -->
        <template v-if="isMultiShipMode">
          <TresGroup
            v-for="shipResult in multiShipPackResults"
            :ref="(el: unknown) => setShipGroupRef(el, shipResult.shipIndex)"
            :key="`ship-${shipResult.shipIndex}-${multiShipPackVersion}`"
            :position="getShipPosition(shipResult)"
          >
            <!-- Ship label (Html from cientos) -->
            <Html :position="[0, shipResult.boundingHeight + 1, 0]" center>
              <span
                class="cargo-grid-viewer__ship-label"
                :style="{ color: shipResult.color }"
              >
                {{ shipResult.name }}
              </span>
            </Html>

            <!-- Hold groups for this ship -->
            <TresGroup
              v-for="group in shipResult.groups"
              :key="`group-${shipResult.shipIndex}-${group.key}`"
              :position="group.position"
            >
              <TresGroup
                v-for="layout in group.holds"
                :key="`hold-${shipResult.shipIndex}-${layout.holdIndex}`"
                :position="layout.position"
              >
                <!-- Hold wireframe in ship color -->
                <TresLineSegments
                  :geometry="createEdgesGeometry(layout.dimensions)"
                  :material="shipEdgeMaterials[shipResult.shipIndex]"
                />

                <!-- Containers inside hold -->
                <TresGroup
                  v-for="(container, cIdx) in layout.containers"
                  :key="`c-${shipResult.shipIndex}-${layout.holdIndex}-${cIdx}`"
                >
                  <TresMesh :position="container.position">
                    <TresBoxGeometry :args="container.dimensions" />
                    <TresMeshStandardMaterial
                      :color="container.color"
                      :transparent="true"
                      :opacity="0.6"
                    />
                  </TresMesh>
                  <TresLineSegments
                    :position="container.position"
                    :geometry="createEdgesGeometry(container.dimensions)"
                    :material="containerEdgeMaterial(container.color)"
                  />
                </TresGroup>
              </TresGroup>
            </TresGroup>
          </TresGroup>
        </template>

        <!-- Single-ship Cargo Hold Groups -->
        <template v-else-if="!isPreviewMode">
          <TresGroup
            v-for="group in groupLayouts"
            :key="`group-${group.key}-${packVersion}`"
            :position="group.position"
          >
            <!-- Individual holds within group -->
            <TresGroup
              v-for="layout in group.holds"
              :key="`hold-${layout.holdIndex}`"
              :position="layout.position"
            >
              <!-- Hold wireframe outline -->
              <TresLineSegments
                :geometry="createEdgesGeometry(layout.dimensions)"
                :material="holdEdgeMaterial"
              />

              <!-- Containers inside hold -->
              <TresGroup
                v-for="(container, cIdx) in layout.containers"
                :key="`c-${layout.holdIndex}-${cIdx}`"
              >
                <TresMesh :position="container.position">
                  <TresBoxGeometry :args="container.dimensions" />
                  <TresMeshStandardMaterial
                    :color="container.color"
                    :transparent="true"
                    :opacity="0.6"
                  />
                </TresMesh>
                <TresLineSegments
                  :position="container.position"
                  :geometry="createEdgesGeometry(container.dimensions)"
                  :material="containerEdgeMaterial(container.color)"
                />
              </TresGroup>
            </TresGroup>
          </TresGroup>
        </template>
      </TresCanvas>
    </div>

    <!-- Multi-ship per-ship stats -->
    <div
      v-if="isMultiShipMode"
      class="cargo-grid-viewer__multi-stats"
      data-test="cargo-grid-viewer-multi-stats"
    >
      <div
        v-for="shipResult in multiShipPackResults"
        :key="`stats-${shipResult.shipIndex}`"
        class="cargo-grid-viewer__ship-stats"
      >
        <div class="cargo-grid-viewer__ship-stats-header">
          <span
            class="cargo-grid-viewer__stat-color"
            :style="{ backgroundColor: shipResult.color }"
          />
          <span class="cargo-grid-viewer__ship-stats-name">
            {{ shipResult.name }}
          </span>
          <Btn
            :size="BtnSizesEnum.SMALL"
            inline
            @click="emit('autoFill', shipResult.shipIndex)"
          >
            {{ t("labels.cargoGridViewer.autoFillShip") }}
          </Btn>
          <Btn
            v-tooltip="t('actions.remove')"
            :size="BtnSizesEnum.SMALL"
            :data-test="`remove-ship-${shipResult.shipIndex}`"
            inline
            @click="emit('removeShip', shipResult.shipIndex)"
          >
            <i class="fa-light fa-times" />
          </Btn>
        </div>
        <div class="cargo-grid-viewer__stats">
          <div class="cargo-grid-viewer__stat">
            <span class="cargo-grid-viewer__stat-label">{{
              t("labels.cargoGridViewer.capacity")
            }}</span>
            <span class="cargo-grid-viewer__stat-value"
              >{{ shipResult.totalSCU }} SCU</span
            >
          </div>
          <div class="cargo-grid-viewer__stat">
            <span class="cargo-grid-viewer__stat-label">{{
              t("labels.cargoGridViewer.maxContainerSize")
            }}</span>
            <span class="cargo-grid-viewer__stat-value"
              >{{ shipResult.maxContainerSize }} SCU</span
            >
          </div>
          <div class="cargo-grid-viewer__stat">
            <span class="cargo-grid-viewer__stat-label">{{
              t("labels.cargoGridViewer.packed")
            }}</span>
            <span class="cargo-grid-viewer__stat-value"
              >{{ shipResult.packedSCU }} SCU</span
            >
          </div>
          <div
            v-for="(count, size) in shipResult.placed"
            :key="`ship-${shipResult.shipIndex}-placed-${size}`"
            class="cargo-grid-viewer__stat"
          >
            <span
              class="cargo-grid-viewer__stat-color"
              :style="{ backgroundColor: CONTAINER_COLORS[Number(size)] }"
            />
            <span class="cargo-grid-viewer__stat-label">{{ size }} SCU</span>
            <span class="cargo-grid-viewer__stat-value"
              >&times;{{ count }}</span
            >
          </div>
          <template
            v-if="
              Object.values(shipResult.notPlaced).some((v: number) => v > 0)
            "
          >
            <div
              class="cargo-grid-viewer__stat cargo-grid-viewer__stat--warning"
            >
              <span class="cargo-grid-viewer__stat-label">{{
                t("labels.cargoGridViewer.didNotFit")
              }}</span>
              <span class="cargo-grid-viewer__stat-value"
                >{{ shipResult.notPlacedSCU }} SCU</span
              >
            </div>
            <div
              v-for="(count, size) in shipResult.notPlaced"
              :key="`ship-${shipResult.shipIndex}-np-${size}`"
              class="cargo-grid-viewer__stat cargo-grid-viewer__stat--warning"
            >
              <span class="cargo-grid-viewer__stat-label">{{ size }} SCU</span>
              <span class="cargo-grid-viewer__stat-value"
                >&times;{{ count }}</span
              >
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
