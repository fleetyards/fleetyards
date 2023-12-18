/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { HangarGroupPublic } from './HangarGroupPublic';
import type { Model } from './Model';
import type { ModelModulePackage } from './ModelModulePackage';
import type { ModelPaint } from './ModelPaint';
import type { ModelUpgrade } from './ModelUpgrade';

export type VehiclePublic = {
    id: string;
    name?: string;
    slug?: string;
    serial?: string;
    hangarGroupIds: Array<string>;
    hangarGroups: Array<HangarGroupPublic>;
    loaner: boolean;
    model: Model;
    username?: string | null;
    userAvatar?: string | null;
    userRsiHandle?: string | null;
    modelModuleIds: Array<string>;
    modelUpgradeIds: Array<string>;
    modulePackage?: ModelModulePackage;
    upgrade?: ModelUpgrade;
    paint?: ModelPaint;
    createdAt: string;
    updatedAt: string;
};

