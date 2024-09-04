// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IInvestmentManager {
    function deposit(address liquidityPool, uint256 amount, address owner) external; 
    function increaseDeposit(address liquidityPool, uint256 amount) external;
    function decreaseDeposit(address liquidityPool, uint256 amount) external;
    function cancelDeposit(address liquidityPool) external;
    function withdraw(address liquidityPool, address owner) external returns (uint256);
    function startEpoch(address liquidityPool) external;
    function endEpoch(address liquidityPool) external;
    function processMaturity(address liquidityPool) external;
    function getInvestorState(address liquidityPool, address investor) external view returns (uint256 depositedAmount, uint256 shares, uint256 pendingDeposit, bool hasWithdrawn);
    function getEpochState(address liquidityPool) external view returns (uint256 startTime, uint256 endTime, uint256 totalDeposits, uint256 totalShares, bool fundsEscrowed, bool matured);
}