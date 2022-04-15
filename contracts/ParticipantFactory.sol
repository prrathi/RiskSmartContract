// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import {Admin} from "./Admin.sol";

contract ParticipantFactory {

    /*
        1.) How do claims work? How does the information come in?
        2.) If there are multiple claims per participant we should 
        have an array storing the claims or have another 
        contract for the claims info
        3.) All investors in a participant's claim don't get same premium
        because of the high risk, high reward attribute the participant 
        who has the claim should have the list of investors to determine 
        how much to pay
            a.) The participant should have access to their investors
    */

    struct Participant {
        uint coverageSize;
        uint premium; //participant premium to investors
        // uint profit;
        // uint totalInvestor;
    }

    struct Payments {
        address investorAddress;
        uint256 paymentToInvestor;
        //Claim if we make contract for claims
    }

    //all participants on platform
    // Participant[] public participants;
    Payments[] public payments;
    // bytes32[] public particpantsIds;
    mapping (bytes32 => Participant) idToParticipant;
    // address[] public participantAddresses;
    
    //address
    mapping (address => bytes32) addresstoId; //for platform
    // mapping (bytes32 => address) idToAddress; //from platform to Participant

    event newParticipant(bytes32 hashUsername, uint coverageSize, uint totalClaims, uint premium);

    constructor(Admin _admin) Component(_admin){}

    function createParticipant(uint _coverageSize, uint _premium, bytes32 hashUsername) public {
        require(admin.Platform().isParticipantOpen, "currently closed");
        //hashing is done here (need to check if this works)
        require(addresstoId[msg.sender] == 0);
        // bytes32 hashUsername = keccak256(abi.encode(username));
        require(!admin.Platform().checkExists(), "Username taken");
        addresstoId[msg.sender] = hashUsername;
        idToParticipant[hashUsername] = Participant(_coverageSize, _premium);
        // admin.Currency().approve(address(this), admin.Platform().premium); //GET ACTUAL APPROVAL MECHANISM
        admin.Currency().transferFrom(msg.sender, address(this), admin.Platform().participantPremium);
        // participantAddresses[hashUsername] = Participant(0, 0);
        admin.Platform()._initiateValue(hashUsername, _value, false, false, msg.sender); 
        emit newParticipant(hashUsername, _coverageSize, _totalClaims, _premium);
    }

    //mapping for values which can all be accessible from the admin.Platform()
    mapping (address => uint) public mapCoverageSize;
    mapping (address => uint) public mapTotalClaims;
    mapping (address => uint) public mapPremium;
    mapping (address => uint) public mapProfit;
    mapping (address => bool) public mapOpen;

    //register the claim
    function registerClaim(bytes32 hashUsername) public {
        require(addresstoId[msg.sender] != 0);
        // string memory hashUsername = keccak256(abi.encode(username));
        require(hashUsername == addresstoId[msg.sender]);
        // Participant storage myParticipant = participantAddresses[hashUsername]; //storage means pass by reference
        admin.Platform().splitClaim(hashUsername);
        // if there is a claim username we would want to push that into claims array
    }

    // //puts investor into array
    // function _updateInvestors(string memory _username) public {
        // //make an array above and push the investors in 
        // //hashes and pushes username
        // //haven't decided how to store yet
    // }


    // do we need all of this, see _payPremium in the platforms.sol
    // only done at end so sophistication isn't needed


    //// payment related attributes and functions
    // mapping (address => bytes32) public addressToPaymentId;
    // mapping (bytes32 => address) public paymentIdToAddress;
    // event newPayment(address _participantId, address _paymentId);  

    // //make a payment
    // function createPayment(address _participantId, address _paymentId) public {
        // payments.push(Payment(_participantId, _paymentId));

        // /*
        // need to figure out how to hash address to bytes32 
        // (make sure whether or not we want to do this or not) 
        // */

        // emit newPayment(address _participantId, address _paymentId);
    // }

    // //makes payment
    // mapping (address => uint) public investorPayments;

    // function calculatePayment() public returns(uint){
        // for(int i = 0; i < payments.length; i++) {
            // //run the math for now, currently we have the payments the same
            // //run payment updater TBD how to do, price amount varies
        // }
    // }


    
    // contract PaymentMade {
        // mapping (address => uint) public payments;

        // function updatePayment(uint newBalance) public {
            // balances[msg.sender] = newBalance;
        // }
    // }

    // contract PaymentUpdater {
        // function updatePayment(uint _amount) public returns (uint) {
            // PaymentMade pay = new PaymentMade();
            // PaymentMade.updatePayment(_amount);
            // return PaymentMade.payments(address(this));
        // }
    // }


}



