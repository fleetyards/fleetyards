/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CelestialObjectSortEnum } from './CelestialObjectSortEnum';
export type CelestialObjectQuery = {
    starsystemEq?: string;
    nameCont?: string;
    nameIn?: Array<string>;
    searchCont?: string;
    parentEq?: string;
    parentIdNull?: boolean;
    /**
     * @deprecated
     */
    main?: boolean;
    sorts?: (Array<CelestialObjectSortEnum> | CelestialObjectSortEnum);
};

