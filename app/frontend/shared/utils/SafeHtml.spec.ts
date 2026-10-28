import { describe, expect, it } from "vitest";
import { sanitizeHtml } from "./SafeHtml";

describe("sanitizeHtml", () => {
  it("keeps the markup the translations use", () => {
    expect(sanitizeHtml("Deleted <b>Alpha</b>.<br>Done")).toBe(
      "Deleted <b>Alpha</b>.<br>Done",
    );
    expect(sanitizeHtml('12 <span class="text-muted">aUEC</span>')).toBe(
      '12 <span class="text-muted">aUEC</span>',
    );
  });

  it("keeps a link and stops it reaching back to the opener", () => {
    expect(
      sanitizeHtml(
        '<a href="https://robertsspaceindustries.com" target="_blank">RSI</a>',
      ),
    ).toBe(
      '<a href="https://robertsspaceindustries.com" target="_blank" rel="noopener noreferrer">RSI</a>',
    );
  });

  it("drops event handlers and the elements that carry them", () => {
    expect(
      sanitizeHtml(
        'Leave <b onclick="x()">A<img src=x onerror="alert(1)"></b>?',
      ),
    ).toBe("Leave <b>A</b>?");
  });

  it("drops a script link and script contents", () => {
    expect(
      sanitizeHtml(
        '<a href="javascript:alert(1)">go</a><script>alert(1)</script>',
      ),
    ).toBe("<a>go</a>");
  });

  it("escapes what it keeps as text", () => {
    expect(sanitizeHtml("<svg><g>1 &lt; 2</g></svg>")).toBe("1 &lt; 2");
  });
});
