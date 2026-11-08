// The library a character file's face is blended from: per mesh of the body's
// head (head, eyes, teeth) the protos head's positions, a weight per region
// and vertex, and every library head's offset from protos. Positions are in
// the meshes' own space, so they go straight into body.glb's geometry and the
// skin keeps working.

export const FACE_PARTS = [
  "EyebrowLeft",
  "EyebrowRight",
  "EyeLeft",
  "EyeRight",
  "Nose",
  "EarLeft",
  "EarRight",
  "CheekLeft",
  "CheekRight",
  "Mouth",
  "Jaw",
  "Crown",
  "Neck",
] as const;

export const FACE_MESHES = ["head", "eyes", "teeth"] as const;

export type FaceMeshName = (typeof FACE_MESHES)[number];

type ArrayDescription = {
  byteOffset: number;
  type: "float32" | "uint8" | "int8" | "uint16";
  shape: number[];
  file?: string;
  sum_per_vertex?: number;
};

export type FaceLibraryIndex = {
  library: string;
  head_count: number;
  heads: { id: number; available: boolean }[];
  meshes: Record<
    FaceMeshName,
    {
      gltf_mesh_name: string;
      vertex_count: number;
      regions: number[];
      base: ArrayDescription;
      masks: ArrayDescription;
      deltas: ArrayDescription;
      delta_scale: ArrayDescription;
      normals?: ArrayDescription;
    }
  >;
};

export type FaceMesh = {
  gltfMeshName: string;
  vertexCount: number;
  regions: number[];
  base: Float32Array;
  masks: Uint8Array;
  // [head][axis][vertex], decoded.
  deltas: Int8Array;
  deltaScale: Float32Array;
  // [head][octahedral x, y][vertex], decoded; the head mesh only.
  normals?: Int8Array;
};

export type FaceLibrary = {
  library: string;
  headCount: number;
  meshes: Record<FaceMeshName, FaceMesh>;
};

// Per part, in FACE_PARTS order, the library heads it blends and their
// weights, which sum to 1.
export type FaceWeights = { part: string; heads: [number, number][] }[];

export type BlendedFace = Record<FaceMeshName, Float32Array> & {
  headNormals?: Float32Array;
};

const count = (shape: number[]) =>
  shape.reduce((total, size) => total * size, 1);

const view = (buffer: ArrayBuffer, description: ArrayDescription) => {
  const length = count(description.shape);
  switch (description.type) {
    case "float32":
      return new Float32Array(
        buffer.slice(
          description.byteOffset,
          description.byteOffset + length * 4,
        ),
      );
    case "uint8":
      return new Uint8Array(buffer, description.byteOffset, length);
    case "int8":
      return new Int8Array(buffer, description.byteOffset, length);
    case "uint16":
      return new Uint16Array(
        buffer.slice(
          description.byteOffset,
          description.byteOffset + length * 2,
        ),
      );
  }
};

// Every row is delta-coded along the vertex index with int8 wrap-around.
export const undelta = (coded: Int8Array, rowLength: number) => {
  const values = new Int8Array(coded.length);
  for (let row = 0; row < coded.length; row += rowLength) {
    let accumulated = 0;
    for (let v = 0; v < rowLength; v++) {
      accumulated = ((accumulated + coded[row + v]) << 24) >> 24;
      values[row + v] = accumulated;
    }
  }
  return values;
};

export const decodeFaceLibrary = (
  index: FaceLibraryIndex,
  library: ArrayBuffer,
  normals?: ArrayBuffer,
): FaceLibrary => {
  const fileFor = (description: ArrayDescription) =>
    description.file === "normals.bin"
      ? normals
      : description.file
        ? undefined
        : library;

  const meshes = Object.fromEntries(
    FACE_MESHES.map((name) => {
      const mesh = index.meshes[name];
      const vertexCount = mesh.vertex_count;
      const normalsFile = mesh.normals ? fileFor(mesh.normals) : undefined;

      return [
        name,
        {
          gltfMeshName: mesh.gltf_mesh_name,
          vertexCount,
          regions: mesh.regions,
          base: view(library, mesh.base) as Float32Array,
          masks: view(library, mesh.masks) as Uint8Array,
          deltas: undelta(view(library, mesh.deltas) as Int8Array, vertexCount),
          deltaScale: view(library, mesh.delta_scale) as Float32Array,
          normals:
            mesh.normals && normalsFile
              ? undelta(
                  view(normalsFile, mesh.normals) as Int8Array,
                  vertexCount,
                )
              : undefined,
        } satisfies FaceMesh,
      ];
    }),
  ) as Record<FaceMeshName, FaceMesh>;

  return { library: index.library, headCount: index.head_count, meshes };
};

const octahedral = (x: number, y: number, out: number[]) => {
  const z = 1 - Math.abs(x) - Math.abs(y);
  const t = Math.max(-z, 0);
  const nx = x - (x >= 0 ? t : -t);
  const ny = y - (y >= 0 ? t : -t);
  const length = Math.hypot(nx, ny, z);
  out[0] = nx / length;
  out[1] = ny / length;
  out[2] = z / length;
};

// pos[v] = base[v] + Σ_r mask[r][v] · Σ_(h, w) in part(regions[r]) w · delta[h][v]
const blendMesh = (
  mesh: FaceMesh,
  weights: FaceWeights,
  withNormals: boolean,
) => {
  const n = mesh.vertexCount;
  const positions = new Float64Array(n * 3);
  for (let i = 0; i < n * 3; i++) positions[i] = mesh.base[i];
  const normals =
    withNormals && mesh.normals ? new Float64Array(n * 3) : undefined;
  const octa = [0, 0, 0];

  mesh.regions.forEach((part, r) => {
    const heads = weights[part]?.heads ?? [[0, 1]];
    for (const [head, weight] of heads) {
      const scale = [0, 1, 2].map((axis) => mesh.deltaScale[head * 3 + axis]);
      for (let v = 0; v < n; v++) {
        const m = mesh.masks[r * n + v];
        if (m === 0) continue;
        const factor = (weight * m) / 255;
        for (let axis = 0; axis < 3; axis++) {
          positions[v * 3 + axis] +=
            factor * mesh.deltas[(head * 3 + axis) * n + v] * scale[axis];
        }
        if (normals && mesh.normals) {
          octahedral(
            mesh.normals[head * 2 * n + v] / 127,
            mesh.normals[(head * 2 + 1) * n + v] / 127,
            octa,
          );
          normals[v * 3] += factor * octa[0];
          normals[v * 3 + 1] += factor * octa[1];
          normals[v * 3 + 2] += factor * octa[2];
        }
      }
    }
  });

  let unitNormals: Float32Array | undefined;
  if (normals) {
    unitNormals = new Float32Array(n * 3);
    for (let v = 0; v < n; v++) {
      const length =
        Math.hypot(normals[v * 3], normals[v * 3 + 1], normals[v * 3 + 2]) || 1;
      unitNormals[v * 3] = normals[v * 3] / length;
      unitNormals[v * 3 + 1] = normals[v * 3 + 1] / length;
      unitNormals[v * 3 + 2] = normals[v * 3 + 2] / length;
    }
  }

  return { positions: Float32Array.from(positions), normals: unitNormals };
};

export const blendFace = (
  library: FaceLibrary,
  weights: FaceWeights,
): BlendedFace => {
  const head = blendMesh(library.meshes.head, weights, true);

  return {
    head: head.positions,
    headNormals: head.normals,
    eyes: blendMesh(library.meshes.eyes, weights, false).positions,
    teeth: blendMesh(library.meshes.teeth, weights, false).positions,
  };
};

// Every part on the protos head: where accessories are authored, so the
// difference to it is what moves them with a blended face.
export const PROTOS_WEIGHTS: FaceWeights = FACE_PARTS.map((part) => ({
  part,
  heads: [[0, 1]],
}));

export type FaceLibraryUrls = {
  index: string;
  positions: string;
  normals: string;
};

const libraries = new Map<string, Promise<FaceLibrary>>();

const fetchBuffer = async (url: string) => {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${url}: ${response.status}`);
  return response.arrayBuffer();
};

// Fetched and decoded once per build.
export const loadFaceLibrary = (library: string, urls: FaceLibraryUrls) => {
  let loading = libraries.get(library);
  if (!loading) {
    loading = Promise.all([
      fetchBuffer(urls.index).then(
        (buffer) =>
          JSON.parse(new TextDecoder().decode(buffer)) as FaceLibraryIndex,
      ),
      fetchBuffer(urls.positions),
      fetchBuffer(urls.normals),
    ]).then(([index, positions, normals]) =>
      decodeFaceLibrary(index, positions, normals),
    );
    loading.catch(() => libraries.delete(library));
    libraries.set(library, loading);
  }
  return loading;
};
