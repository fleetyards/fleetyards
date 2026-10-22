import { afterEach, describe, expect, it, vi } from "vitest";
import downloadJs from "downloadjs";
import { canSharePlaques, savePlaque } from "./download";

vi.mock("downloadjs", () => ({ default: vi.fn() }));

const file = new File(["png"], "fleetyards-plaque.png", { type: "image/png" });

const share = vi.fn();

// Only the fields `savePlaque` reads; `standalone` is set by iOS alone.
const stubNavigator = ({
  standalone,
  canShare = true,
}: {
  standalone?: boolean;
  canShare?: boolean;
}) => {
  vi.stubGlobal("navigator", { standalone, canShare: () => canShare, share });
};

describe("savePlaque", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.mocked(downloadJs).mockReset();
    share.mockReset();
  });

  it("hands the picture to the share sheet in the iOS Home Screen app", async () => {
    stubNavigator({ standalone: true });

    await savePlaque(file);

    expect(share).toHaveBeenCalledWith({ files: [file] });
    expect(downloadJs).not.toHaveBeenCalled();
  });

  it("downloads the picture in a browser tab", async () => {
    stubNavigator({ standalone: false });

    await savePlaque(file);

    expect(downloadJs).toHaveBeenCalledWith(file, file.name, "image/png");
    expect(share).not.toHaveBeenCalled();
  });

  it("downloads the picture in an app installed outside iOS", async () => {
    stubNavigator({});

    await savePlaque(file);

    expect(downloadJs).toHaveBeenCalled();
    expect(share).not.toHaveBeenCalled();
  });

  it("downloads the picture where files cannot be shared", async () => {
    stubNavigator({ standalone: true, canShare: false });

    await savePlaque(file);

    expect(downloadJs).toHaveBeenCalled();
    expect(share).not.toHaveBeenCalled();
  });
});

describe("canSharePlaques", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("asks the browser whether a PNG can be shared", () => {
    const canShare = vi.fn(() => true);
    vi.stubGlobal("navigator", { canShare });

    expect(canSharePlaques()).toBe(true);
    expect(canShare).toHaveBeenCalledWith({
      files: [expect.objectContaining({ type: "image/png" })],
    });
  });

  it("is false where the browser cannot share at all", () => {
    vi.stubGlobal("navigator", {});

    expect(canSharePlaques()).toBe(false);
  });
});
