// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Platform} from "./Platform.sol";

contract PlatformSetup {
    Platform internal _platform;

    modifier onlyPlatform() {
        require(msg.sender == address(_platform));
        _;
    }

    function initialize(Platform platform_) public { //add modifier initializer
        _platform = platform_;
    }
}