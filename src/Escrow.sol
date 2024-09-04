// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IEscrow.sol";

contract Escrow is IEscrow, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => bool) public authorizedManagers;

    event ManagerAuthorized(address manager);
    event ManagerDeauthorized(address manager);
    event FundsReceived(address token, uint256 amount);
    event FundsTransferred(address token, address recipient, uint256 amount);

    modifier onlyAuthorizedManager() {
        require(authorizedManagers[msg.sender], "Escrow: caller is not an authorized manager");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function authorizeManager(address manager) external onlyOwner {
        require(manager != address(0), "Escrow: invalid manager address");
        authorizedManagers[manager] = true;
        emit ManagerAuthorized(manager);
    }

    function deauthorizeManager(address manager) external onlyOwner {
        authorizedManagers[manager] = false;
        emit ManagerDeauthorized(manager);
    }

    function transferIn(address token, uint256 amount) external override onlyAuthorizedManager nonReentrant {
        require(token != address(0), "Escrow: invalid token address");
        require(amount > 0, "Escrow: amount must be greater than 0");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit FundsReceived(token, amount);
    }

    function transferOut(address token, address recipient, uint256 amount) external override onlyAuthorizedManager nonReentrant {
        require(token != address(0), "Escrow: invalid token address");
        require(recipient != address(0), "Escrow: invalid recipient address");
        require(amount > 0, "Escrow: amount must be greater than 0");

        IERC20(token).safeTransfer(recipient, amount);
        emit FundsTransferred(token, recipient, amount);
    }

    function getBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}