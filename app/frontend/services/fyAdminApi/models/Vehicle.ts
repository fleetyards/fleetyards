/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BoughtViaEnum } from './BoughtViaEnum';
import type { HangarGroup } from './HangarGroup';
import type { Model } from './Model';
import type { ModelModulePackage } from './ModelModulePackage';
import type { ModelPaint } from './ModelPaint';
import type { ModelUpgrade } from './ModelUpgrade';
import type { User } from './User';
export type Vehicle = {
    id: string;
    name?: string;
    slug?: string;
    serial?: string;
    user: User;
    alternativeNames: Array<string>;
    boughtVia: BoughtViaEnum;
    boughtViaLabel?: string;
    flagship: boolean;
    hangarGroupIds: Array<string>;
    hangarGroups: Array<HangarGroup>;
    loaner: boolean;
    model: Model;
    modelModuleIds: Array<string>;
    modelUpgradeIds: Array<string>;
    modulePackage?: ModelModulePackage;
    nameVisible: boolean;
    paint?: ModelPaint;
    public: boolean;
    saleNotify: boolean;
    upgrade?: ModelUpgrade;
    wanted: boolean;
    hidden: boolean;
    createdAt: string;
    updatedAt: string;
};

