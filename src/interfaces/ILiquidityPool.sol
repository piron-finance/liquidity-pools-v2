// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./IERC7575.sol";

interface ILiquidityPool is IERC7575 {
    function asset() external view returns (address);
    function share() external view returns (address);
    function epochInProgress() external view returns (bool);
    function startNextEpoch() external;
    function endEpoch() external;
}