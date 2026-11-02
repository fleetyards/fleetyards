export enum AllowedFileTypes {
  IMAGE = "image",
  VIDEO = "video",
  AUDIO = "audio",
  PDF = "pdf",
  HOLO = "holo",
  AR_HOLO = "arHolo",
}

export const fileTypeMap: Record<AllowedFileTypes, string[]> = {
  image: ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"],
  video: ["video/mp4", "video/webm", "video/ogg"],
  audio: ["audio/mpeg", "audio/ogg", "audio/wav"],
  pdf: ["application/pdf"],
  holo: ["application/octet-stream", "model/gltf+json", "model/gltf-binary"],
  // Apart from the holos: no 3D view here reads USDZ, so it is never previewed
  // as one.
  arHolo: ["model/vnd.usdz+zip"],
};

// The browser takes `File.type` from the operating system's registry, and
// Windows registers nothing for glTF or USDZ, so a valid model arrives typed "".
// Only these extensions are guessed: anything else without a type stays untyped.
const typesByExtension: Record<string, string> = {
  glb: "model/gltf-binary",
  gltf: "model/gltf+json",
  usdz: "model/vnd.usdz+zip",
};

export const fileTypeOf = (file: Pick<File, "name" | "type">): string => {
  if (file.type) {
    return file.type;
  }

  const extension = /\.([^./]+)$/.exec(file.name)?.[1].toLowerCase() ?? "";

  return typesByExtension[extension] ?? "";
};
