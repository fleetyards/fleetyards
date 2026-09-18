import { useI18n } from "@/shared/composables/useI18n";

export type MissionNameSegment = {
  text: string;
  slot: boolean;
};

// The game fills these in when it offers the contract, so the export carries
// the template rather than a title: 1,293 of the 4,030 mission names on
// blueprint sources hold at least one. Rendered raw they read as broken data
// ("Keep ~mission(Location) Safe"); dropped, the sentence loses its object.
const TOKEN = /~\w+\(([^)]*)\)/g;

// The token's head names what varies. A pipe narrows it to a particular
// wording -- `Location|Address`, `TargetName|Last` -- which is the same noun,
// so only the head is read.
const NOUNS: Record<string, string> = {
  location: "location",
  defendlocationwrapperlocation: "location",
  objects: "objects",
  targetname: "target",
  ship: "ship",
  cargogradetoken: "cargo",
  reputationrank: "rank",
  danger: "danger",
  contractor: "contract",
};

export const useMissionName = () => {
  const { t } = useI18n();

  const nounFor = (inner: string) => {
    const head = inner.split("|")[0].trim().toLowerCase();

    return t(`labels.blueprint.missionSlots.${NOUNS[head] || "other"}`);
  };

  /**
   * The title split into the parts that are fixed and the parts the game
   * fills in, so a reader can see the shape of the contract without being
   * shown a template token.
   */
  const segments = (name: string): MissionNameSegment[] => {
    const parts: MissionNameSegment[] = [];
    let cursor = 0;

    for (const match of name.matchAll(TOKEN)) {
      const at = match.index ?? 0;
      if (at > cursor)
        parts.push({ text: name.slice(cursor, at), slot: false });

      parts.push({ text: nounFor(match[1]), slot: true });
      cursor = at + match[0].length;
    }

    if (cursor < name.length) {
      parts.push({ text: name.slice(cursor), slot: false });
    }

    return parts;
  };

  // 131 titles are nothing but a token -- the whole name is a reference the
  // export does not resolve -- and "a contract" alone says less than the kind
  // the source already carries.
  const isTokenOnly = (name: string) =>
    segments(name).every((segment) => segment.slot);

  return { segments, isTokenOnly };
};
