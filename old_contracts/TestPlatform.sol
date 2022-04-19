pragma solidity >= 0.6.0;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/NewPlatform.sol";

contract TestPlatform {
    function testPlatformAddress() public {
        NewPlatform platform = NewPlatform(DeployedAddresses.NewPlatform());
        bytes32 participantName = keccak256("participant1");
        // Assert.equal(platform.createParticipant(participantName), 100, "money not right");
    }
}