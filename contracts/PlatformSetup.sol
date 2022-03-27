pragma solidity >=0.8.11;

import {Platform} from "./Platforms.sol";

abstract contract PlatformSetup{
    Platform internal immutable _platform;

    modifier onlyPlatform() {
        require(msg.sender == address(_platform));
        _;
    }

    constructor(Platform platform_) {
        _platform = platform_;
    }
}