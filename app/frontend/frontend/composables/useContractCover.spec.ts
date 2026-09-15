import { describe, expect, it } from "vitest";
import { useContractCover } from "./useContractCover";
import { FleetContractKindEnum } from "@/services/fyApi";

const { resolve } = useContractCover();

const contract = (kind: FleetContractKindEnum) => ({ kind }) as never;

describe("useContractCover", () => {
  // Dropping a file into images/contracts/ is meant to take precedence over the
  // mission stand-in without a code change - see that folder's README. The
  // assertion is on the filename, because the whole mechanism is the glob
  // keying `crafting.webp` to the `crafting` kind.
  it("uses the art in images/contracts for a kind that has some", () => {
    expect(resolve(contract(FleetContractKindEnum.CRAFTING), null)).toContain(
      "crafting",
    );
  });

  // The two kinds with no art of their own still resolve to the mission cover
  // that comes closest rather than to the generic placeholder.
  it("falls back to the closest mission art for a kind that has none", () => {
    const transport = resolve(contract(FleetContractKindEnum.TRANSPORT), null);
    const procurement = resolve(
      contract(FleetContractKindEnum.PROCUREMENT),
      null,
    );

    expect(transport).toContain("cargo_hauling");
    expect(procurement).toContain("other");
  });

  /*
   * The model writes the kind into `cover_image_preset` whenever the form left
   * it empty, so nearly every contract carries one. Reading that as a choice
   * put a default ahead of the cover the fleet configured for this kind, which
   * is the one thing here somebody deliberately set up.
   */
  it("does not let a kind-shaped default outrank the fleet's cover", () => {
    const fleet = {
      contractCovers: { crafting: { mediumUrl: "/uploads/own-cover.webp" } },
    } as never;
    const defaulted = {
      kind: FleetContractKindEnum.CRAFTING,
      coverImagePreset: "crafting",
    } as never;

    expect(resolve(defaulted, fleet)).toBe("/uploads/own-cover.webp");
  });

  // Anything else is art somebody picked, and the picker offers every kind's.
  it("keeps a preset that names something other than the kind", () => {
    const fleet = {
      contractCovers: { crafting: { mediumUrl: "/uploads/own-cover.webp" } },
    } as never;
    const chosen = {
      kind: FleetContractKindEnum.CRAFTING,
      coverImagePreset: "transport",
    } as never;

    // No transport art ships, so the choice resolves to nothing and the fleet's
    // cover still answers -- what matters is that a real file would have won.
    expect(resolve(chosen, fleet)).toBe("/uploads/own-cover.webp");

    const craftingAlt = {
      kind: FleetContractKindEnum.TRANSPORT,
      coverImagePreset: "crafting",
    } as never;

    expect(resolve(craftingAlt, fleet)).toContain("crafting");
  });

  // A fleet that uploaded its own cover sees that, not the built-in one.
  it("prefers the fleet's own upload over everything", () => {
    const fleet = {
      contractCovers: { crafting: { mediumUrl: "/uploads/own-cover.webp" } },
    } as never;

    expect(resolve(contract(FleetContractKindEnum.CRAFTING), fleet)).toBe(
      "/uploads/own-cover.webp",
    );
  });

  it("falls back to the placeholder without a contract", () => {
    expect(resolve(null, null)).toContain("store_image");
  });
});
