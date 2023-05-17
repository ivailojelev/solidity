// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract RepairService {
    uint private reqId = 0;
    address payable ownerOne = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    address ownerTwo = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    string[5] availableRepairs = ["Floor", "Roof", "Door", "Window", "Staircase"];
    mapping (string => bool) private acceptedRepairs;
    mapping(uint requestId => repairRequest) private repairRequests;
    struct repairRequest {
        uint createdAt;
        address requestedBy;
        string requestDescription;
        bool accepted;
        bool confirmedByOwnerOne;
        bool confirmedByOwnerTwo;
        bool resolved;
        uint256 tax;
    }

    constructor() {
        _setAvailablePayments();
    }

    function addRepairRequest(string calldata requestDescription) external payable {
        require(msg.value >= 1, "insufficient funds");
        repairRequests[reqId] = repairRequest(block.timestamp, msg.sender, requestDescription, false, false, false, false, msg.value);
        reqId++;
    }

    function acceptRepairRequest(uint requestId) public {
        require(msg.sender == ownerOne || msg.sender == ownerTwo, "Not an owner");
        require(acceptedRepairs[repairRequests[requestId].requestDescription], "Invalid repair request. We only accept requests for Floor, Roof, Door, Window and Staircase");
        repairRequests[requestId].accepted = true;
    }

    function confirmRepairRequest(uint requestId) public {
        repairRequest storage repRequest = repairRequests[requestId];
        require(msg.sender == ownerOne || msg.sender == ownerTwo, "Not an owner");
        require(repRequest.accepted, "Repair request not accepted");

        if (msg.sender == ownerOne) {
            repRequest.confirmedByOwnerOne = true;
        } else if (msg.sender == ownerTwo) {
            repRequest.confirmedByOwnerTwo = true;
        }

        if (repRequest.confirmedByOwnerOne && repRequest.confirmedByOwnerTwo) {
            payForTheRepairs(requestId);
        }
    }

    function payForTheRepairs(uint requestId) public payable {
        require(msg.sender == ownerOne || msg.sender == ownerTwo, "Not an owner");
        ownerOne.transfer(repairRequests[requestId].tax);
        repairRequests[requestId].resolved = true;
    }

    function _setAvailablePayments() private {
        for (uint i = 0; i < availableRepairs.length; i++) {
            acceptedRepairs[availableRepairs[i]] = true;
        }
    }

    function payBack(uint requestId) public payable {
        require(msg.sender == ownerOne || msg.sender == ownerTwo, "Not an owner");
        repairRequest storage repRequest = repairRequests[requestId];
        require(!repRequest.resolved, "Request has been resolved");
        uint currentDate = block.timestamp;
        uint daysSince = (currentDate - repRequest.createdAt) / (3600*24);
        if (daysSince >= 31) {
            payable(repRequest.requestedBy).transfer(repRequest.tax);
        }
    }

    function getRepairRequest(uint requestId) external view returns (repairRequest memory) {
        return repairRequests[requestId];
    }
}