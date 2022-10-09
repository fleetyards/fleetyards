import Qs from "qs";

type LinkHeader = {
  url: string;
  rel: string;
  [key: string]: string;
};

type ParsedLinks = {
  [key: string]: LinkHeader;
};

function extractUrl(part: string): string | undefined {
  const match = part.match(/<?([^>]*)>/);

  if (match && match[1]) {
    return match[1];
  }

  return undefined;
}

function extractRel(part: string): string | undefined {
  const match = part.match(/\s*.+\s*=\s*"?([^"]+)"?/);

  if (match && match[1]) {
    return match[1];
  }

  return undefined;
}

function parseLink(link: string): LinkHeader | undefined {
  const parts = link.split(";");

  if (parts.length < 1) {
    return undefined;
  }

  const rel = extractRel(parts[1]);
  const url = extractUrl(parts[0]);

  if (!url || !rel) {
    return undefined;
  }

  const urlParts = url.split("?");
  const queryParams = Qs.parse(urlParts[1]);

  return {
    url,
    rel,
    ...queryParams,
  };
}

const parseHeader = function parseHeader(
  linkHeader: string
): ParsedLinks | undefined {
  if (!linkHeader) {
    return undefined;
  }

  const links = {};

  linkHeader.split(/,\s*</).forEach((rawLink: string) => {
    const link = parseLink(rawLink);

    if (link && link.rel) {
      links[link.rel] = link;
    }
  });

  if (Object.keys(links).length === 0) {
    return undefined;
  }

  return links;
};

export default parseHeader;
