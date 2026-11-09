import type { BufferGeometry } from "three";

// How far each head vertex moved from the protos head, which every accessory
// is authored on: hair, brows and beard move with the face by it.
export const faceOffsets = (blended: Float32Array, protos: Float32Array) => {
  const offsets = new Float32Array(blended.length);
  for (let i = 0; i < blended.length; i++) offsets[i] = blended[i] - protos[i];
  return offsets;
};

// pos[v] += Σ_k weight[v][k] · offset[index[v][k]], over the four head vertices
// an accessory vertex is bound to.
export const followFace = (
  positions: Float32Array,
  indices: ArrayLike<number>,
  weights: ArrayLike<number>,
  offsets: Float32Array,
) => {
  const out = new Float32Array(positions);
  const count = positions.length / 3;
  for (let v = 0; v < count; v++) {
    for (let k = 0; k < 4; k++) {
      const weight = weights[v * 4 + k];
      if (!weight) continue;
      const head = indices[v * 4 + k] * 3;
      out[v * 3] += weight * offsets[head];
      out[v * 3 + 1] += weight * offsets[head + 1];
      out[v * 3 + 2] += weight * offsets[head + 2];
    }
  }
  return out;
};

// A copy of the geometry with its points moved by the face binding it carries;
// the geometry itself when it carries none.
export const bindToFace = (geometry: BufferGeometry, offsets: Float32Array) => {
  const index = geometry.getAttribute("_head_idx");
  const weight = geometry.getAttribute("_head_w");
  const position = geometry.getAttribute("position");
  if (!index || !weight || !position) return geometry;

  const moved = geometry.clone();
  moved
    .getAttribute("position")
    .array.set(
      followFace(
        position.array as Float32Array,
        index.array,
        weight.array,
        offsets,
      ),
    );
  moved.getAttribute("position").needsUpdate = true;
  moved.computeBoundingBox();
  moved.computeBoundingSphere();
  return moved;
};

const MIN_DISTANCE = 0.0005;
const CELL = 0.02;

// A hat, cap, bandana or mask that has no binding of its own is bound like the
// hair: each point to its four nearest protos head points, weighted by inverse
// square distance with a 0.5 mm floor.
export const fitToFace = (
  positions: Float32Array,
  protos: Float32Array,
  offsets: Float32Array,
) => {
  const cells = new Map<string, number[]>();
  const cellOf = (x: number, y: number, z: number) =>
    `${Math.floor(x / CELL)},${Math.floor(y / CELL)},${Math.floor(z / CELL)}`;
  for (let i = 0; i < protos.length / 3; i++) {
    const key = cellOf(protos[i * 3], protos[i * 3 + 1], protos[i * 3 + 2]);
    let cell = cells.get(key);
    if (!cell) cells.set(key, (cell = []));
    cell.push(i);
  }

  const count = positions.length / 3;
  const indices = new Uint32Array(count * 4);
  const weights = new Float32Array(count * 4);
  const nearest: [number, number][] = [];

  for (let v = 0; v < count; v++) {
    const x = positions[v * 3];
    const y = positions[v * 3 + 1];
    const z = positions[v * 3 + 2];
    const cx = Math.floor(x / CELL);
    const cy = Math.floor(y / CELL);
    const cz = Math.floor(z / CELL);

    // Rings of cells outward until four points are found and no closer one
    // can lie beyond the ring searched.
    nearest.length = 0;
    for (let ring = 0; ring < 64; ring++) {
      for (let dx = -ring; dx <= ring; dx++) {
        for (let dy = -ring; dy <= ring; dy++) {
          for (let dz = -ring; dz <= ring; dz++) {
            if (Math.max(Math.abs(dx), Math.abs(dy), Math.abs(dz)) !== ring)
              continue;
            for (const i of cells.get(`${cx + dx},${cy + dy},${cz + dz}`) ??
              []) {
              const d = Math.hypot(
                protos[i * 3] - x,
                protos[i * 3 + 1] - y,
                protos[i * 3 + 2] - z,
              );
              nearest.push([d, i]);
            }
          }
        }
      }
      if (nearest.length >= 4) {
        nearest.sort((a, b) => a[0] - b[0]);
        if (nearest[3][0] <= ring * CELL) break;
      }
    }
    nearest.sort((a, b) => a[0] - b[0]);

    let total = 0;
    for (let k = 0; k < 4 && k < nearest.length; k++) {
      const weight = 1 / Math.max(nearest[k][0], MIN_DISTANCE) ** 2;
      indices[v * 4 + k] = nearest[k][1];
      weights[v * 4 + k] = weight;
      total += weight;
    }
    for (let k = 0; k < 4; k++) weights[v * 4 + k] /= total || 1;
  }

  return followFace(positions, indices, weights, offsets);
};
