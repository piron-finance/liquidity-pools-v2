// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IEscrow.sol";
import "./interfaces/ILiquidityPool.sol";
// import "hardhat/console.sol";

contract InvestmentManager {
    using Math for uint256;
    using SafeERC20 for IERC20;

    struct InvestorState {
        uint256 depositedAmount;
        uint256 shares;
        uint256 pendingDeposit;
        bool hasWithdrawn;
    }

    struct EpochState {
    uint256 startTime;
    uint256 endTime;
    uint256 totalDeposits;
    uint256 totalShares;
    uint256 totalReturn;
    bool fundsEscrowed;
    bool matured;
}

    mapping(address => mapping(address => InvestorState)) public investorStates;
    mapping(address => EpochState) public epochStates;
    mapping(address => address[]) private poolInvestors;
    mapping(address => mapping(address => bool)) private isInvestor;


    IEscrow public immutable escrow;
    uint256 public immutable interestRate;
    uint256 public constant EPOCH_DURATION = 3 minutes;

    event Deposit(address indexed liquidityPool, address indexed investor, uint256 amount, uint256 shares);
    event EpochStarted(address indexed liquidityPool, uint256 startTime, uint256 endTime);
    event EpochEnded(address indexed liquidityPool, uint256 totalDeposits);
    event FundsEscrowed(address indexed liquidityPool, uint256 amount);
    event Withdrawal(address indexed liquidityPool, address indexed investor, uint256 amount, uint256 shares);

    constructor(address _escrow, uint256 _interestRate) {
        escrow = IEscrow(_escrow);
        interestRate = _interestRate;
    }

     function startEpoch(address liquidityPool) external {
        require(epochStates[liquidityPool].endTime < block.timestamp, "Current epoch not ended");
        uint256 startTime = block.timestamp;
         (bool success, uint256 endTime) = startTime.tryAdd(EPOCH_DURATION);
    require(success, "Epoch end time calculation overflow");
        epochStates[liquidityPool] = EpochState({
            startTime: startTime,
            endTime: endTime,
            totalDeposits: 0,
            totalShares: 0,
            fundsEscrowed: false,
            matured: false,
            totalReturn: 0
        });
        emit EpochStarted(liquidityPool, startTime, endTime);
    }

   
    function deposit(address liquidityPool, uint256 amount, address owner) external returns (uint256 shares) {
        require(block.timestamp < epochStates[liquidityPool].endTime, "Deposit epoch ended");

        InvestorState storage state = investorStates[liquidityPool][owner];
        if (!isInvestor[liquidityPool][owner]) {
            poolInvestors[liquidityPool].push(owner);
            isInvestor[liquidityPool][owner] = true;
        }

        state.pendingDeposit = state.pendingDeposit.tryAdd(amount);
        epochStates[liquidityPool].totalDeposits = epochStates[liquidityPool].totalDeposits.add(amount);

        shares = convertToShares(liquidityPool, amount);
        state.shares = state.shares.add(shares);
        epochStates[liquidityPool].totalShares = epochStates[liquidityPool].totalShares.add(shares);

        emit Deposit(liquidityPool, owner, amount, shares);
        return shares;
    }

    function increaseDeposit(address liquidityPool, uint256 amount) external {
        require(block.timestamp < epochStates[liquidityPool].endTime, "Deposit epoch ended");
        IERC20(ILiquidityPool(liquidityPool).asset()).safeTransferFrom(msg.sender, address(this), amount);

        InvestorState storage state = investorStates[liquidityPool][msg.sender]; // fix sender
        state.pendingDeposit = state.pendingDeposit.add(amount);
        epochStates[liquidityPool].totalDeposits = epochStates[liquidityPool].totalDeposits.add(amount);

        // emit DepositIncreased(liquidityPool, msg.sender, amount);
    }

       function decreaseDeposit(address liquidityPool, uint256 amount) external {
        require(block.timestamp < epochStates[liquidityPool].endTime, "Deposit epoch ended");
        InvestorState storage state = investorStates[liquidityPool][msg.sender]; //fix sender
        require(state.pendingDeposit >= amount, "Insufficient pending deposit");

        state.pendingDeposit = state.pendingDeposit.sub(amount);
        epochStates[liquidityPool].totalDeposits = epochStates[liquidityPool].totalDeposits.sub(amount);
        IERC20(ILiquidityPool(liquidityPool).asset()).safeTransfer(msg.sender, amount);

        // emit DepositDecreased(liquidityPool, msg.sender, amount);
    }

    function cancelDeposit(address liquidityPool) external {
        require(block.timestamp < epochStates[liquidityPool].endTime, "Deposit epoch ended");
        InvestorState storage state = investorStates[liquidityPool][msg.sender]; // fix sender
        uint256 amount = state.pendingDeposit;
        require(amount > 0, "No pending deposit");

        state.pendingDeposit = 0;
        epochStates[liquidityPool].totalDeposits = epochStates[liquidityPool].totalDeposits.sub(amount);
        IERC20(ILiquidityPool(liquidityPool).asset()).safeTransfer(msg.sender, amount);

        // emit DepositCancelled(liquidityPool, msg.sender, amount);
    }


     

    // function endEpoch(address liquidityPool) external {
    //     require(block.timestamp >= epochStates[liquidityPool].endTime, "Epoch not ended yet");
    //     require(!epochStates[liquidityPool].fundsEscrowed, "Funds already escrowed");

    //     uint256 totalDeposits = epochStates[liquidityPool].totalDeposits;
    //     IERC20 asset = IERC20(ILiquidityPool(liquidityPool).asset());
    //     asset.approve(address(escrow), totalDeposits);
    //     escrow.transferIn(address(asset), totalDeposits);

    //     epochStates[liquidityPool].fundsEscrowed = true;

    //     for (uint i = 0; i < poolInvestors[liquidityPool].length; i++) {
    //         address investor = poolInvestors[liquidityPool][i];
    //         InvestorState storage state = investorStates[liquidityPool][investor];
    //         state.depositedAmount = state.depositedAmount.add(state.pendingDeposit);
    //         state.pendingDeposit = 0;
    //     }

    //      epochStates[liquidityPool].matured = true;

    //     emit EpochEnded(liquidityPool, totalDeposits);
    //     emit FundsEscrowed(liquidityPool, totalDeposits);
    // }


//   function processMaturity(address liquidityPool) external {
//         require(epochStates[liquidityPool].fundsEscrowed, "Funds not escrowed yet");
//         require(!epochStates[liquidityPool].matured, "Already matured");
        
//         uint256 totalReturn = IERC20(ILiquidityPool(liquidityPool).asset()).balanceOf(address(escrow));
//         require(totalReturn > 0, "No funds returned from escrow");
        
//         epochStates[liquidityPool].matured = true;
//     }

   function processDepositsAndEndEpoch(address liquidityPool) external {
    require(block.timestamp >= epochStates[liquidityPool].endTime, "Epoch not ended yet");
    require(!epochStates[liquidityPool].fundsEscrowed, "Funds already escrowed");

    _processDeposits(liquidityPool);
    _escrowFunds(liquidityPool);
    _calculateReturns(liquidityPool);

    emit EpochEnded(liquidityPool, epochStates[liquidityPool].totalDeposits);
}

function _calculateReturns(address liquidityPool) internal {
    uint256 totalDeposits = epochStates[liquidityPool].totalDeposits;
    uint256 interest = totalDeposits.mul(interestRate).div(100);
    uint256 totalReturn = totalDeposits.add(interest);
    
    epochStates[liquidityPool].totalReturn = totalReturn;
    
    // emit ReturnsCalculated(liquidityPool, totalReturn);
}

    function _processDeposits(address liquidityPool) internal {
        for (uint i = 0; i < poolInvestors[liquidityPool].length; i++) {
            address investor = poolInvestors[liquidityPool][i];
            InvestorState storage state = investorStates[liquidityPool][investor];
            state.depositedAmount = state.depositedAmount.add(state.pendingDeposit);
            state.pendingDeposit = 0;
        }
    }

    function _escrowFunds(address liquidityPool) internal {
        uint256 totalDeposits = epochStates[liquidityPool].totalDeposits;
        IERC20 asset = IERC20(ILiquidityPool(liquidityPool).asset());
        asset.approve(address(escrow), totalDeposits);
        escrow.transferIn(address(asset), totalDeposits);

        epochStates[liquidityPool].fundsEscrowed = true;
        epochStates[liquidityPool].matured = true;
        emit FundsEscrowed(liquidityPool, totalDeposits);
    }

function withdraw(address liquidityPool, address receiver, uint256 assets) external returns (uint256 shares) {
    require(epochStates[liquidityPool].matured, "Not matured yet");
    InvestorState storage state = investorStates[liquidityPool][receiver];
    
    uint256 totalDeposits = epochStates[liquidityPool].totalDeposits;
    uint256 totalReturn = epochStates[liquidityPool].totalReturn;
    uint256 maxWithdrawable = state.shares.mul(totalReturn).div(totalDeposits);
    
    require(assets <= maxWithdrawable, "Insufficient balance");
    
    shares = assets.mul(totalDeposits).div(totalReturn);
    require(state.shares >= shares, "Insufficient shares");

    state.shares = state.shares.sub(shares);
    epochStates[liquidityPool].totalShares = epochStates[liquidityPool].totalShares.sub(shares);

    IERC20 asset = IERC20(ILiquidityPool(liquidityPool).asset());
    escrow.transferOut(address(asset), receiver, assets);

    if (state.shares == 0) {
        removeInvestor(liquidityPool, receiver);
    }

    emit Withdrawal(liquidityPool, receiver, assets, shares);
    return shares;
}


    function getInvestors(address liquidityPool) public view returns (address[] memory) {
        return poolInvestors[liquidityPool];
    }

     function removeInvestor(address liquidityPool, address investor) internal {
        if (isInvestor[liquidityPool][investor]) {
            isInvestor[liquidityPool][investor] = false;
            for (uint i = 0; i < poolInvestors[liquidityPool].length; i++) {
                if (poolInvestors[liquidityPool][i] == investor) {
                    poolInvestors[liquidityPool][i] = poolInvestors[liquidityPool][poolInvestors[liquidityPool].length - 1];
                    poolInvestors[liquidityPool].pop();
                    break;
                }
            }
        }
    }


    function getTotalAssets(address liquidityPool) external view returns (uint256) {
        return epochStates[liquidityPool].totalDeposits;
    }

    function maxWithdrawAmount(address liquidityPool, address investor) public view returns (uint256) {
    require(epochStates[liquidityPool].matured, "Epoch not matured yet");
    InvestorState storage state = investorStates[liquidityPool][investor];
    
    uint256 totalDeposits = epochStates[liquidityPool].totalDeposits;
    uint256 totalReturn = epochStates[liquidityPool].totalReturn;
    
    return state.shares.mul(totalReturn).div(totalDeposits);
}



   function convertToShares(address liquidityPool, uint256 assets) public view returns (uint256) {
        EpochState storage epoch = epochStates[liquidityPool];
        return epoch.totalShares == 0 ? assets : assets.mul(epoch.totalShares).div(epoch.totalDeposits);
    }

    function convertToAssets(address liquidityPool, uint256 shares) public view returns (uint256) {
    EpochState storage epoch = epochStates[liquidityPool];
    if (epoch.matured) {
        return shares.mul(epoch.totalReturn).div(epoch.totalDeposits);
    } else {
        return shares;
    }
}




    function getInvestorState(address liquidityPool, address investor) external view returns (uint256 depositedAmount, uint256 shares, uint256 pendingDeposit, bool hasWithdrawn) {
        InvestorState memory state = investorStates[liquidityPool][investor];
        return (state.depositedAmount, state.shares, state.pendingDeposit, state.hasWithdrawn);
    }

    function getEpochState(address liquidityPool) external view returns (uint256 startTime, uint256 endTime, uint256 totalDeposits, uint256 totalShares, bool fundsEscrowed, bool matured) {
        EpochState memory state = epochStates[liquidityPool];
        return (state.startTime, state.endTime, state.totalDeposits, state.totalShares, state.fundsEscrowed, state.matured);
    }

}