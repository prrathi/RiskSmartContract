pragma solidity ^0.8.0;
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Admin} from "./Admin.sol";

abstract contract Component is Initializable {
    Admin internal immutable admin; 
    modifier onlyPlatform() {
        require(msg.sender == address(admin.Platform()));
        _;
    }
    modifier onlyComponent() {
        require(msg.sender == address(admin.Platform()) || msg.sender == address(admin.InvestorFactory()) || msg.sender == address(admin.InvestorFactory()));
        _;
    }
    modifier onlyTrading() {
        require(msg.sender == address(admin.Trading()));
    }
    constructor(Admin admin_) {
        admin = admin_;
    }
}