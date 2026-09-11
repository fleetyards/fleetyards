import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { globSync } from "node:fs";
import { parse, compileTemplate } from "vue/compiler-sfc";

/*
 * A `<style>` or `<script>` nested inside `<template>` compiles to nothing and
 * takes the whole component with it — "Tags with side effect (<script> and
 * <style>) are ignored in client component templates". Neither `vue-tsc` nor a
 * unit suite catches it: the template parses, and a component nothing mounts is
 * never compiled. It surfaces only as a Vite overlay in the browser, which is
 * how one shipped.
 *
 * Compiling every SFC is cheap because nothing is executed.
 */
const files = globSync("app/frontend/**/*.vue", {
  exclude: (path) => path.includes("node_modules"),
});

describe("every SFC compiles", () => {
  it("finds the components to check", () => {
    expect(files.length).toBeGreaterThan(100);
  });

  it.each(files)("%s", (file) => {
    const { descriptor, errors } = parse(readFileSync(file, "utf8"), {
      filename: file,
    });

    // `compileTemplate` reports strings as well as error objects, so both
    // sides are flattened to messages rather than kept as a union.
    const messages: string[] = errors.map((error) => error.message);

    if (descriptor.template) {
      const { errors: templateErrors } = compileTemplate({
        source: descriptor.template.content,
        filename: file,
        id: "compile-check",
      });

      messages.push(
        ...templateErrors.map((error) =>
          typeof error === "string" ? error : error.message,
        ),
      );
    }

    expect(messages).toEqual([]);
  });
});
