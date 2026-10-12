export type PlaqueCreditRole =
  "founders" | "shipwrights" | "designers" | "directors" | "operations";

export type PlaqueCreditGroup = {
  role: PlaqueCreditRole;
  names: string[];
};

// The people who make the game, credited the way Cloud Imperium's own plaque on
// its "The Only Constant" set credits them. Only names with a public credit at
// the studio are listed: the plaque photo alone is too blurry to trust for the
// spelling of someone's name. Every column holds as many names as the others,
// so the plaque stays even.
export const PLAQUE_CREDITS: PlaqueCreditGroup[] = [
  {
    role: "founders",
    names: [
      "Chris Roberts",
      "Erin Roberts",
      "Ortwin Freyermuth",
      "Brian Chambers",
      "Carl Jones",
    ],
  },
  {
    role: "shipwrights",
    names: [
      "John Crewe",
      "Chris Smith",
      "Yogi Klatt",
      "Joe Neville",
      "Josh Coons",
    ],
  },
  {
    role: "designers",
    names: [
      "Elwin Bachiller Jr",
      "Jim Martin",
      "Gavin Rothery",
      "Ryan Church",
      "Kemp Remillard",
    ],
  },
  {
    role: "directors",
    names: [
      "Tony Zurovec",
      "Marco Corbetta",
      "Mark Skelton",
      "Paul Jones",
      "Nathan Dearsley",
    ],
  },
  {
    role: "operations",
    names: [
      "Francesca McKibben",
      "Eric Kieron Davis",
      "Brian Stich",
      "Mike Jones",
      "John Erskine",
    ],
  },
];
