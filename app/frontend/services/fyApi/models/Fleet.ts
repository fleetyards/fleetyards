/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { FleetMembershipRoleEnum } from './FleetMembershipRoleEnum';

export type Fleet = {
    myRole?: FleetMembershipRoleEnum;
    primary?: boolean;
    myFleet?: boolean;
    id: string;
    fid: string;
    rsiSid?: string | null;
    ts?: string | null;
    discord?: string | null;
    youtube?: string | null;
    twitch?: string | null;
    guilded?: string | null;
    homepage?: string | null;
    name: string;
    slug: string;
    description?: string | null;
    publicFleet: boolean;
    logo?: string | null;
    backgroundImage?: string | null;
    createdAt: string;
    updatedAt: string;
};

