import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import downloadJs from "downloadjs";
import { isInstalledApp } from "@/shared/utils/DisplayMode";
import { savePlaque } from "./download";

vi.mock("downloadjs", () => ({ default: vi.fn() }));
vi.mock("@/shared/utils/DisplayMode", () => ({ isInstalledApp: vi.fn() }));

const file = new File(["png"], "fleetyards-plaque.png", { type: "image/png" });

describe("savePlaque", () => {
  const share = vi.fn();

  beforeEach(() => {
    vi.stubGlobal("navigator", {
      ...navigator,
      canShare: () => true,
      share,
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.mocked(downloadJs).mockReset();
    share.mockReset();
  });

  it("hands the picture to the share sheet in a Home Screen app", async () => {
    vi.mocked(isInstalledApp).mockReturnValue(true);

    await savePlaque(file);

    expect(share).toHaveBeenCalledWith({ files: [file] });
    expect(downloadJs).not.toHaveBeenCalled();
  });

  it("downloads the picture in a browser tab", async () => {
    vi.mocked(isInstalledApp).mockReturnValue(false);

    await savePlaque(file);

    expect(downloadJs).toHaveBeenCalledWith(file, file.name, "image/png");
    expect(share).not.toHaveBeenCalled();
  });

  it("downloads the picture where files cannot be shared", async () => {
    vi.mocked(isInstalledApp).mockReturnValue(true);
    vi.stubGlobal("navigator", { ...navigator, canShare: () => false, share });

    await savePlaque(file);

    expect(downloadJs).toHaveBeenCalled();
    expect(share).not.toHaveBeenCalled();
  });
});
