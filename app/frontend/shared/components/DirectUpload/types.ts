export enum AllowedFileTypes {
  IMAGE = "image",
  VIDEO = "video",
  AUDIO = "audio",
  PDF = "pdf",
  HOLO = "holo",
}

export const fileTypeMap: Record<AllowedFileTypes, string[]> = {
  image: ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"],
  video: ["video/mp4", "video/webm", "video/ogg"],
  audio: ["audio/mpeg", "audio/ogg", "audio/wav"],
  pdf: ["application/pdf"],
  holo: ["application/octet-stream", "model/gltf+json", "model/gltf-binary"],
};
