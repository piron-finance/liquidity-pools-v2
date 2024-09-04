// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.22;

interface IInvestmentManager {
    function deposit(address liquidityPool, uint256 amount, address owner) external returns(uint256); 
    function increaseDeposit(address liquidityPool, uint256 amount) external;
    function decreaseDeposit(address liquidityPool, uint256 amount) external;
    function cancelDeposit(address liquidityPool) external;
    function withdraw(address liquidityPool, address receiver, uint256 shares) external returns (uint256);
    function startEpoch(address liquidityPool) external;
   function processDepositsAndEndEpoch(address liquidityPool) external;
    function processMaturity(address liquidityPool) external;
    function getInvestorState(address liquidityPool, address investor) external view returns (uint256 depositedAmount, uint256 shares, uint256 pendingDeposit, bool hasWithdrawn);
    function getEpochState(address liquidityPool) external view returns (uint256 startTime, uint256 endTime, uint256 totalDeposits, uint256 totalShares, bool fundsEscrowed, bool matured);
     function getTotalAssets(address liquidityPool) external view returns (uint256);
      function convertToShares(address liquidityPool, uint256 assets) external view returns (uint256);
      function convertToAssets(address liquidityPool, uint256 shares) external view returns (uint256);
        function maxWithdrawAmount(address liquidityPool, address investor) external view returns (uint256);
}