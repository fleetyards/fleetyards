/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BoughtViaEnum } from './BoughtViaEnum';
export type VehicleUpdateInput = {
    name?: string | null;
    serial?: string | null;
    wanted?: boolean | null;
    nameVisible?: boolean | null;
    public?: boolean | null;
    saleNotify?: boolean | null;
    flagship?: boolean | null;
    modelPaintId?: string | null;
    boughtVia?: BoughtViaEnum | null;
    hangarGroupIds?: Array<string> | null;
    modelModuleIds?: Array<string> | null;
    modelUpgradeIds?: Array<string> | null;
    alternativeNames?: Array<string> | null;
};

