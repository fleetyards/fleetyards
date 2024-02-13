/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Fleet } from './Fleet';
import type { FleetMembershipRoleEnum } from './FleetMembershipRoleEnum';
import type { FleetMembershipShipsFilterEnum } from './FleetMembershipShipsFilterEnum';
import type { FleetMembershipStatusEnum } from './FleetMembershipStatusEnum';
export type FleetMember = {
    id: string;
    username: string;
    role: FleetMembershipRoleEnum;
    roleLabel: string;
    status?: FleetMembershipStatusEnum;
    avatar?: string;
    rsiHandle?: string;
    homepage?: string;
    discord?: string;
    youtube?: string;
    twitch?: string;
    guilded?: string;
    shipsFilter: FleetMembershipShipsFilterEnum;
    hangarGroupId?: string;
    fleetSlug: string;
    fleetName: string;
    fleet?: Fleet;
    primary?: boolean;
    hangarUpdatedAt?: string;
    invitedAt?: string;
    invitedAtLabel?: string;
    requestedAt?: string;
    requestedAtLabel?: string;
    acceptedAt?: string;
    acceptedAtLabel?: string;
    declinedAt?: string;
    declinedAtLabel?: string;
    createdAt: string;
    updatedAt: string;
};

