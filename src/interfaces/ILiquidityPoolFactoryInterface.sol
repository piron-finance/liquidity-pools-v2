// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface ILiquidityPoolFactory {
    function newLiquidityPool(address _asset, string memory _name, string memory _symbol, uint64 poolId_) external returns (address);
}