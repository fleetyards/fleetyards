import {
  BufferAttribute,
  type BufferGeometry,
  type InterleavedBufferAttribute,
  Matrix3,
  Matrix4,
  type Object3D,
  type Skeleton,
  type SkinnedMesh,
  Vector3,
} from "three";

type Attribute = BufferAttribute | InterleavedBufferAttribute;

// An attribute's values as plain floats, whatever the file stored them as: a
// quantized holo's are normalized integers, and an interleaved one's array is
// the whole interleaved buffer.
export const floatArray = (attribute: Attribute): Float32Array => {
  if (
    attribute.array instanceof Float32Array &&
    !(attribute as InterleavedBufferAttribute).isInterleavedBufferAttribute
  ) {
    return attribute.array;
  }

  const { count, itemSize } = attribute;
  const out = new Float32Array(count * itemSize);
  for (let index = 0; index < count; index++) {
    for (let component = 0; component < itemSize; component++) {
      out[index * itemSize + component] = attribute.getComponent(
        index,
        component,
      );
    }
  }

  return out;
};

const isQuantized = (attribute: Attribute | undefined) =>
  !!attribute &&
  (!(attribute.array instanceof Float32Array) || attribute.normalized);

const floatAttribute = (attribute: Attribute) =>
  new BufferAttribute(floatArray(attribute), attribute.itemSize);

const closeTo = (a: Matrix4, b: Matrix4) => {
  const scale = Math.max(1, ...a.elements.map(Math.abs));

  return a.elements.every(
    (value, index) => Math.abs(value - b.elements[index]) <= scale * 1e-4,
  );
};

// What the skeleton does to the stored points in its rest pose, when every
// bone agrees on it. A quantized skin keeps its dequantization in the inverse
// bind matrices, so a skeleton standing in its bind pose maps each point from
// the [-1, 1] box back to where it was authored. Bones that disagree mean a
// rest pose that is not the bind pose, and then nothing can be told apart.
const restTransform = (mesh: SkinnedMesh) => {
  const { bones, boneInverses } = mesh.skeleton;
  let rest: Matrix4 | undefined;

  for (let index = 0; index < bones.length; index++) {
    const transform = new Matrix4()
      .multiplyMatrices(mesh.bindMatrixInverse, bones[index].matrixWorld)
      .multiply(boneInverses[index])
      .multiply(mesh.bindMatrix);

    if (!rest) rest = transform;
    else if (!closeTo(rest, transform)) return undefined;
  }

  return rest;
};

const bake = (geometry: BufferGeometry, transform: Matrix4) => {
  const baked = geometry.clone();
  const linear = new Matrix3().setFromMatrix4(transform);
  const normalMatrix = new Matrix3().getNormalMatrix(transform);

  const position = floatAttribute(geometry.getAttribute("position"));
  position.applyMatrix4(transform);
  baked.setAttribute("position", position);

  const normal = geometry.getAttribute("normal");
  if (normal) {
    const floats = floatAttribute(normal);
    floats.applyNormalMatrix(normalMatrix);
    baked.setAttribute("normal", floats);
    baked.normalizeNormals();
  }

  const tangent = geometry.getAttribute("tangent");
  if (tangent) {
    const floats = floatAttribute(tangent);
    const direction = new Vector3();
    for (let index = 0; index < floats.count; index++) {
      direction
        .fromBufferAttribute(floats, index)
        .transformDirection(transform);
      floats.setXYZ(index, direction.x, direction.y, direction.z);
    }
    baked.setAttribute("tangent", floats);
  }

  // Morph targets are offsets: scaled with the points, never moved.
  baked.morphAttributes.position = (
    geometry.morphAttributes.position ?? []
  ).map((target) => floatAttribute(target).applyMatrix3(linear));
  baked.morphAttributes.normal = (geometry.morphAttributes.normal ?? []).map(
    (target) => floatAttribute(target).applyNormalMatrix(normalMatrix),
  );
  if (!geometry.morphAttributes.position) {
    delete baked.morphAttributes.position;
  }
  if (!geometry.morphAttributes.normal) delete baked.morphAttributes.normal;

  baked.computeBoundingBox();
  baked.computeBoundingSphere();

  return baked;
};

// A quantized skin's points stored back where they were authored, its bind
// matrices undoing as much. The dressing room reads a body's points as they
// were authored: the face library's vertices go onto its head, worn pieces
// are fitted to that face, and its parts are told apart by their height in
// the bind pose. A ship or an item is only ever measured through its node
// transforms, and keeps its smaller quantized points.
export const dequantizeSkins = (scene: Object3D) => {
  scene.updateMatrixWorld(true);

  const baked = new Map<BufferGeometry, [Matrix4, BufferGeometry][]>();
  const skins: SkinnedMesh[] = [];

  scene.traverse((node) => {
    const mesh = node as SkinnedMesh;
    if (
      mesh.isSkinnedMesh &&
      isQuantized(mesh.geometry.getAttribute("position"))
    )
      skins.push(mesh);
  });

  // Measured before any is corrected: every primitive of a mesh, and every
  // node naming the same skin, shares one skeleton.
  const measured = skins.flatMap((mesh) => {
    const transform = restTransform(mesh);
    return transform ? [{ mesh, transform }] : [];
  });

  const corrected = new Set<Skeleton>();

  for (const { mesh, transform } of measured) {
    const original = mesh.geometry;
    const known = baked.get(original) ?? [];
    let geometry = known.find(([done]) => closeTo(done, transform))?.[1];
    if (!geometry) {
      geometry = bake(original, transform);
      known.push([transform, geometry]);
      baked.set(original, known);
    }
    mesh.geometry = geometry;

    if (corrected.has(mesh.skeleton)) continue;
    corrected.add(mesh.skeleton);

    const undo = new Matrix4()
      .copy(mesh.bindMatrix)
      .multiply(new Matrix4().copy(transform).invert())
      .multiply(new Matrix4().copy(mesh.bindMatrix).invert());
    mesh.skeleton.boneInverses.forEach((inverse) => inverse.multiply(undo));
  }
};
