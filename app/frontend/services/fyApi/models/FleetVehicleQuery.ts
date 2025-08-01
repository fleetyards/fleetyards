/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FleetVehicleSortEnum } from './FleetVehicleSortEnum';
export type FleetVehicleQuery = {
    beamGteq?: number;
    beamLteq?: number;
    classificationIn?: Array<string>;
    focusIn?: Array<string>;
    heightGteq?: number;
    heightLteq?: number;
    lengthGteq?: number;
    lengthLteq?: number;
    manufacturerIn?: Array<string>;
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
    modelNameCont?: string;
    modelNameOrModelDescriptionCont?: string;
    loanerEq?: boolean;
    memberIn?: Array<string>;
    sorts?: (Array<FleetVehicleSortEnum> | FleetVehicleSortEnum);
};

