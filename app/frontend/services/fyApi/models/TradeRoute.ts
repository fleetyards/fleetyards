/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { TradeRouteCommodity } from './TradeRouteCommodity';
import type { TradeRouteLeg } from './TradeRouteLeg';
export type TradeRoute = {
    id: string;
    origin?: TradeRouteLeg;
    destination?: TradeRouteLeg;
    commodity?: TradeRouteCommodity;
    buyPrice?: number;
    averageBuyPrice?: number;
    sellPrice?: number;
    averageSellPrice?: number;
    profitPerUnit?: number;
    averageProfitPerUnit?: number;
    profitPerUnitPercent?: number;
    averageProfitPerUnitPercent?: number;
    createdAt: string;
    updatedAt: string;
};

