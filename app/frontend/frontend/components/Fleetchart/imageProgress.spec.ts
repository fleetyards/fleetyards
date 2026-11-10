import { describe, expect, it } from "vitest";
import { createImageProgress } from "./imageProgress";

describe("createImageProgress", () => {
  it("counts a round of pictures until the last one arrives", () => {
    const progress = createImageProgress();

    progress.pending("a");
    progress.pending("b");
    progress.pending("a");

    expect(progress.requested.value).toBe(2);
    expect(progress.outstanding.value).toBe(2);

    progress.settled("a");
    progress.settled("a");

    expect(progress.outstanding.value).toBe(1);

    progress.settled("b");
    progress.pending("c");

    expect(progress.requested.value).toBe(1);
    expect(progress.outstanding.value).toBe(1);
  });
});
