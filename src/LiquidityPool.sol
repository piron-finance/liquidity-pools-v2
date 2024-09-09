// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IERC7575.sol";
import "./interfaces/IInvestmentManager.sol";

contract LiquidityPool is ERC20, IERC7575 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    IInvestmentManager public immutable manager;

    mapping(address => address[]) private poolInvestors;
mapping(address => mapping(address => bool)) private isInvestor;

    constructor(string memory name, string memory symbol, address _asset, address _manager) ERC20(name, symbol) {
        asset = IERC20(_asset);
        manager = IInvestmentManager(_manager);
    }

    function startEpoch() public {
        manager.startEpoch(address(this));  
    }

    function endEpoch() public {
       manager.processDepositsAndEndEpoch(address(this)); 
    }

    function deposit(uint256 assets, address receiver) external override returns (uint256 shares) {
        require(receiver != address(0), "Invalid receiver");
        asset.safeTransferFrom(msg.sender, address(manager), assets);
        shares = manager.deposit(address(this), assets, msg.sender);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
        return shares;
    }

   function mint(uint256 shares, address receiver) external override returns (uint256 assets) {
        require(receiver != address(0), "Invalid receiver");
        assets = convertToAssets(shares);
        asset.safeTransferFrom(msg.sender, address(manager), assets);
        uint256 actualShares = manager.deposit(address(this), assets, msg.sender);
        _mint(receiver, actualShares);
        emit Deposit(msg.sender, receiver, assets, actualShares);
        return assets;
    }

 
    function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256 shares) {
    require(receiver != address(0), "Invalid receiver");
    require(owner != address(0), "Invalid owner");
    if (msg.sender != owner) {
        _spendAllowance(owner, msg.sender, assets);
    }
    shares = manager.withdraw(address(this), receiver, assets);
    _burn(owner, shares);
    emit Withdraw(msg.sender, receiver, owner, assets, shares);
    return shares;
}

    function redeem(uint256 shares, address receiver, address owner) external override returns (uint256 assets) {
        require(receiver != address(0), "Invalid receiver");
        require(owner != address(0), "Invalid owner");
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        assets = manager.withdraw(address(this), receiver, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return assets;
    }

    function totalAssets() public view override returns (uint256) {
        return manager.getTotalAssets(address(this));
    }

    function convertToShares(uint256 assets) public view override returns (uint256) {
        return manager.convertToShares(address(this), assets);
    }

function convertToAssets(uint256 shares) public view override returns (uint256) {
    return manager.convertToAssets(address(this), shares);
}

    function maxDeposit(address) public view override returns (uint256) {
        (,uint256 endTime,,,,) = manager.getEpochState(address(this));
        return block.timestamp < endTime ? type(uint256).max : 0;
    }

    function maxMint(address) public view override returns (uint256) {
        (,uint256 endTime,,,,) = manager.getEpochState(address(this));
        return block.timestamp < endTime ? type(uint256).max : 0;
    }

 function maxWithdraw(address owner) public view override returns (uint256) {
    (,,,,, bool matured) = manager.getEpochState(address(this));
    return matured ? manager.maxWithdrawAmount(address(this), owner) : 0;
}

function getUserBalance(address user) public view returns (uint256) {
    return manager.maxWithdrawAmount(address(this), user);
}

    function maxRedeem(address owner) public view override returns (uint256) {
        (,,,,, bool matured) = manager.getEpochState(address(this));
        return matured ? balanceOf(owner) : 0;
    }

    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }
}