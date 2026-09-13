/*
 * Visibility is spelled as two booleans per surface -- a public one and a
 * narrower one for friends or for allied fleets -- and the rule between them is
 * that public wins: while a surface is published, the narrower switch is never
 * consulted.
 *
 * That is true everywhere and visible only in the settings forms, so this is
 * the one place it is written down. A narrower switch left live under a public
 * one invites somebody to turn it off and expect that to mean something.
 *
 * Disabling it is only half of saying so: off and greyed reads as "allies
 * cannot see the ships", which is the opposite of what a public fleet means.
 * So the switch is also handed `implied` while the public one is on -- it reads
 * as on, and goes back to the value it actually holds when public goes off.
 */
export const narrowerAudienceDisabled = (
  isPublic: unknown,
  submitting: boolean,
) => submitting || !!isPublic;
