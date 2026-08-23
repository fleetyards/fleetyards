import { describe, expect, it } from "vitest";
import { errorTypeFrom } from "./ErrorTypes";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";

const failedWith = (status: number) => ({
  isAxiosError: true,
  response: { status },
});

describe("errorTypeFrom", () => {
  it("reads a refused request as forbidden rather than an outage", () => {
    expect(errorTypeFrom(failedWith(403))).toBe(ErrorTypesEnum.FORBIDDEN);
  });

  it("reads a missing record as not found", () => {
    expect(errorTypeFrom(failedWith(404))).toBe(ErrorTypesEnum.NOT_FOUND);
  });

  it("reads everything else as an error", () => {
    expect(errorTypeFrom(failedWith(500))).toBe(ErrorTypesEnum.ERROR);
    expect(errorTypeFrom(failedWith(422))).toBe(ErrorTypesEnum.ERROR);
  });

  it("has no verdict without a response", () => {
    expect(errorTypeFrom(new Error("boom"))).toBeUndefined();
    expect(errorTypeFrom(undefined)).toBeUndefined();
  });
});
