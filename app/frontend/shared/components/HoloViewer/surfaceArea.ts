import { type BufferGeometry, Triangle, Vector3 } from "three";

// Past this many triangles a mesh is sampled: the total only sets how faint
// the layers are drawn, and a hull of millions held the page walking them all.
const SAMPLED_TRIANGLES = 200_000;

const triangle = new Triangle();

// A geometry's surface in its own units, sampled evenly on a large one.
export const surfaceArea = (geometry: BufferGeometry) => {
  const position = geometry.getAttribute("position");
  if (!position) return 0;

  const index = geometry.getIndex();
  const count = Math.floor((index ? index.count : position.count) / 3);
  const step = Math.max(1, Math.ceil(count / SAMPLED_TRIANGLES));
  const vertex = (corner: number) => (index ? index.getX(corner) : corner);

  let area = 0;
  let sampled = 0;

  for (let face = 0; face < count; face += step) {
    triangle.a.fromBufferAttribute(position, vertex(face * 3));
    triangle.b.fromBufferAttribute(position, vertex(face * 3 + 1));
    triangle.c.fromBufferAttribute(position, vertex(face * 3 + 2));
    area += triangle.getArea();
    sampled += 1;
  }

  return sampled ? (area * count) / sampled : 0;
};

// How many times over a model's surface would wrap the box it fits in: a plain
// shell is about one, a ship with decks and rooms inside it several.
export const surfaceLayers = (area: number, size: Vector3) => {
  const boxArea = 2 * (size.x * size.y + size.y * size.z + size.z * size.x);

  return boxArea > 0 ? Math.max(1, area / boxArea) : 1;
};
