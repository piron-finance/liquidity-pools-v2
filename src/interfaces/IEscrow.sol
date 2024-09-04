// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IEscrow {
     function authorizeManager(address manager) external ;
    function transferIn(address token, uint256 amount) external;
    function transferOut(address token, address recipient, uint256 amount) external;
}