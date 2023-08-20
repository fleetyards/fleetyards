/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { HangarGroupPublic } from './HangarGroupPublic';
import type { Model } from './Model';
import type { ModelModulePackage } from './ModelModulePackage';
import type { ModelPaint } from './ModelPaint';

export type VehiclePublic = {
    id: string;
    name?: string | null;
    slug?: string | null;
    serial?: string | null;
    hangarGroupIds: Array<string>;
    hangarGroups: Array<HangarGroupPublic>;
    loaner: boolean;
    model: Model;
    username?: string | null;
    userAvatar?: string | null;
    modelModuleIds: Array<string>;
    modelUpgradeIds: Array<string>;
    modulePackage?: ModelModulePackage | null;
    paint?: ModelPaint | null;
    createdAt: string;
    updatedAt: string;
};

