pragma solidity >=0.8.11;
import {IERC20} from "./IERC20.sol";
interface IToken is IERC20{
    // functions to insert
    function getMaxLossRatio() external view returns (uint256);
    function getPaymentFreq() external view returns (uint256);
}