import { beforeEach, describe, expect, it, vi } from "vitest";

const uploaded = vi.hoisted(() => ({ files: [] as File[] }));

vi.mock("@rails/activestorage", () => ({
  DirectUpload: class {
    constructor(file: File) {
      uploaded.files.push(file);
    }

    create(callback: (error: string | null, blob?: object) => void) {
      callback(null, { signed_id: "signed" });
    }
  },
}));

import { useDirectUpload } from "./useDirectUpload";

const upload = async (file: File) => {
  await useDirectUpload().uploadFile(file, { progressHandler: () => {} });

  return uploaded.files[0];
};

beforeEach(() => {
  uploaded.files = [];
});

describe("useDirectUpload", () => {
  it("uploads a file the browser could not type under its extension's type", async () => {
    const sent = await upload(new File(["PK"], "flight_holo.usdz"));

    expect(sent.type).toBe("model/vnd.usdz+zip");
    expect(sent.name).toBe("flight_holo.usdz");
  });

  it("uploads a typed file as it is", async () => {
    const file = new File(["png"], "top.png", { type: "image/png" });

    expect(await upload(file)).toBe(file);
  });
});
