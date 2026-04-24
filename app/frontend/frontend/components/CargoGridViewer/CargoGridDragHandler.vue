<script lang="ts">
export default {
  name: "CargoGridDragHandler",
};
</script>

<script lang="ts" setup>
import { useTres } from "@tresjs/core";
import { Raycaster, Vector2, Vector3, Plane, type Group } from "three";
import { SCU_UNIT } from "./constants";

type Props = {
  shipGroups: { ref: Group | null; shipIndex: number }[];
  enabled: boolean;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  dragStart: [shipIndex: number];
  dragMove: [shipIndex: number, offset: [number, number, number]];
  dragEnd: [shipIndex: number];
}>();

const { camera, renderer } = useTres();

const raycaster = new Raycaster();
const mouse = new Vector2();
const dragPlane = new Plane(new Vector3(0, 1, 0), 0);
const dragStartPoint = new Vector3();
const dragGroupStartPos = new Vector3();

const isDragging = ref(false);
const dragShipIndex = ref<number | null>(null);

defineExpose({ isDragging });

const getCanvasElement = (): HTMLCanvasElement | null => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const r = renderer as any;
  return r?.value?.domElement || r?.domElement || null;
};

const updateMouse = (event: PointerEvent, canvas: HTMLCanvasElement) => {
  const rect = canvas.getBoundingClientRect();
  mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
  mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
};

const snapToGrid = (value: number): number => {
  return Math.round(value / SCU_UNIT) * SCU_UNIT;
};

const onPointerDown = (event: PointerEvent) => {
  if (!props.enabled || !camera.value) return;

  const canvas = getCanvasElement();
  if (!canvas) return;

  updateMouse(event, canvas);
  raycaster.setFromCamera(mouse, camera.value);

  // Test intersection with ship group children
  for (const shipGroup of props.shipGroups) {
    if (!shipGroup.ref) continue;

    const intersects = raycaster.intersectObjects(shipGroup.ref.children, true);
    if (intersects.length > 0) {
      isDragging.value = true;
      dragShipIndex.value = shipGroup.shipIndex;

      // Record start point on drag plane
      raycaster.ray.intersectPlane(dragPlane, dragStartPoint);
      dragGroupStartPos.copy(shipGroup.ref.position);

      emit("dragStart", shipGroup.shipIndex);
      canvas.style.cursor = "grabbing";
      event.preventDefault();
      return;
    }
  }
};

const onPointerMove = (event: PointerEvent) => {
  if (!isDragging.value || dragShipIndex.value === null || !camera.value)
    return;

  const canvas = getCanvasElement();
  if (!canvas) return;

  updateMouse(event, canvas);
  raycaster.setFromCamera(mouse, camera.value);

  const currentPoint = new Vector3();
  raycaster.ray.intersectPlane(dragPlane, currentPoint);

  const dx = currentPoint.x - dragStartPoint.x;
  const dz = currentPoint.z - dragStartPoint.z;

  const newX = snapToGrid(dragGroupStartPos.x + dx);
  const newZ = snapToGrid(dragGroupStartPos.z + dz);

  emit("dragMove", dragShipIndex.value, [
    newX - dragGroupStartPos.x,
    0,
    newZ - dragGroupStartPos.z,
  ]);
};

const onPointerUp = () => {
  if (!isDragging.value || dragShipIndex.value === null) return;

  const canvas = getCanvasElement();
  if (canvas) canvas.style.cursor = "";

  emit("dragEnd", dragShipIndex.value);
  isDragging.value = false;
  dragShipIndex.value = null;
};

onMounted(() => {
  const canvas = getCanvasElement();
  if (canvas) {
    canvas.addEventListener("pointerdown", onPointerDown);
    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", onPointerUp);
  }
});

onUnmounted(() => {
  const canvas = getCanvasElement();
  if (canvas) {
    canvas.removeEventListener("pointerdown", onPointerDown);
  }
  window.removeEventListener("pointermove", onPointerMove);
  window.removeEventListener("pointerup", onPointerUp);
});
</script>

<template>
  <!-- Renderless component - provides drag functionality inside TresCanvas -->
</template>
