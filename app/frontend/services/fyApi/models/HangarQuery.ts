/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { BoughtViaEnum } from './BoughtViaEnum';
import type { VehicleSortEnum } from './VehicleSortEnum';

export type HangarQuery = {
    beamGteq?: number;
    beamLteq?: number;
    classificationIn?: Array<string>;
    descriptionCont?: string;
    focusIn?: Array<string>;
    heightGteq?: number;
    heightLteq?: number;
    idIn?: Array<string>;
    idNotIn?: Array<string>;
    lengthGteq?: number;
    lengthLteq?: number;
    manufacturerIn?: Array<string>;
    nameCont?: string;
    nameIn?: Array<string>;
    nameOrDescriptionCont?: string;
    onSaleEq?: boolean;
    pledgePriceGteq?: number;
    pledgePriceLteq?: number;
    pledgePriceIn?: Array<number>;
    priceGteq?: number;
    priceLteq?: number;
    priceIn?: Array<number>;
    productionStatusIn?: Array<string>;
    searchCont?: string;
    sizeIn?: Array<string>;
    modelNameOrModelDescriptionCont?: string;
    publicEq?: boolean;
    loanerEq?: boolean;
    boughtViaEq?: BoughtViaEnum;
    hangarGroupsIn?: Array<string>;
    hangarGroupsNotIn?: Array<string>;
    willItFit?: string;
    sorts?: (Array<VehicleSortEnum> | VehicleSortEnum);
};

