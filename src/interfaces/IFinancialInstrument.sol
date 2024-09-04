// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFinancialInstrument {
    function getInstrumentType() external view returns (bytes32);
    function getIssuer() external view returns (address);
    function getMaturityDate() external view returns (uint256);
    function getFaceValue() external view returns (uint256);
    function getAdditionalData() external view returns (bytes memory);
}