// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Donation {
    enum CauseStatus { Open, Closed, Completed }

    struct Cause {
        string name;
        string description;
        address payable beneficiary;
        uint256 goalAmount;
        uint256 currentAmount;
        uint256 withdrawnAmount;
        CauseStatus status;
        string imageUrl;
    }

    struct TopDonor {
        address donor;
        uint256 amount;
    }

    address public owner;
    mapping(uint256 => Cause) public causes;
    mapping(uint256 => TopDonor[]) public topDonors;
    TopDonor[] public overallTopDonors;
    uint256 public causeCount;

    event DonationMade(uint256 causeId, address donor, uint256 amount);
    event DonationReceived(uint256 causeId, address donor, uint256 amount);
    event CauseClosed(uint256 causeId, address indexed beneficiary);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createCause(string memory name, address payable beneficiary, string memory description, uint256 goalAmount, string memory imageUrl) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(goalAmount > 0, "Goal amount must be greater than zero");
        require(bytes(imageUrl).length > 0, "Image URL cannot be empty");
        
        causeCount++;
        causes[causeCount] = Cause(name, description, beneficiary, goalAmount, 0, 0, CauseStatus.Open, imageUrl);
    }

    function donate(uint256 causeId) public payable {
        Cause storage cause = causes[causeId];
        require(cause.status == CauseStatus.Open, "Cause is closed");
        require(msg.value > 0, "Donation amount must be greater than zero");
        uint256 remainingAmount = cause.goalAmount - cause.currentAmount;
        require(msg.value <= remainingAmount, "Donation amount exceeds the remaining goal amount");

        cause.currentAmount += msg.value;
        emit DonationMade(causeId, msg.sender, msg.value);
        updateTopDonors(causeId, msg.sender, msg.value);
    }

    function getTopDonors(uint256 causeId) public view returns (TopDonor[] memory) {
        require(causeId <= causeCount, "Invalid cause ID");
        return topDonors[causeId];
    }

    function getOverallTopDonors() public view returns (TopDonor[] memory) {
        return overallTopDonors;
    }

    function updateTopDonors(uint256 causeId, address donor, uint256 amount) internal {
        TopDonor[] storage causeDonors = topDonors[causeId];
        TopDonor[] storage allDonors = overallTopDonors;

        bool existingDonor = false;
        uint256 existingDonorIndex;

        for (uint256 i = 0; i < causeDonors.length; i++) {
            if (causeDonors[i].donor == donor) {
                existingDonor = true;
                existingDonorIndex = i;
                break;
            }
        }

        if (existingDonor) {
            causeDonors[existingDonorIndex].amount += amount;
        } else {
            if (causeDonors.length < 10) {
                causeDonors.push(TopDonor(donor, amount));
            } else {
                uint256 minIndex = 0;
                uint256 minValue = causeDonors[0].amount;

                for (uint256 i = 1; i < causeDonors.length; i++) {
                    if (causeDonors[i].amount < minValue) {
                        minIndex = i;
                        minValue = causeDonors[i].amount;
                    }
                }

                if (amount > minValue) {
                    causeDonors[minIndex] = TopDonor(donor, amount);
                }
            }
        }

        existingDonor = false;

        for (uint256 i = 0; i < allDonors.length; i++) {
            if (allDonors[i].donor == donor) {
                existingDonor = true;
                existingDonorIndex = i;
                break;
            }
        }

        if (existingDonor) {
            allDonors[existingDonorIndex].amount += amount;
        } else {
            if (allDonors.length < 10) {
                allDonors.push(TopDonor(donor, amount));
            } else {
                uint256 minIndex = 0;
                uint256 minValue = allDonors[0].amount;

                for (uint256 i = 1; i < allDonors.length; i++) {
                    if (allDonors[i].amount < minValue) {
                        minIndex = i;
                        minValue = allDonors[i].amount;
                    }
                }

                if (amount > minValue) {
                    allDonors[minIndex] = TopDonor(donor, amount);
                }
            }
        }
    }

    function requestDonation(uint256 causeId, uint256 amount) public {
        Cause storage cause = causes[causeId];
        require(cause.status == CauseStatus.Open, "Cause is closed");
        require(amount > 0, "Requested amount must be greater than zero");
        require(amount <= cause.currentAmount, "Requested amount exceeds the available funds");

        cause.beneficiary.transfer(amount);
        cause.withdrawnAmount += amount;
        emit DonationReceived(causeId, msg.sender, amount);
    }

    function closeCause(uint256 causeId) public {
        Cause storage cause = causes[causeId];
        require(causeId <= causeCount, "Invalid cause ID");
        require(cause.beneficiary == msg.sender, "Only beneficiary can close cause");

        cause.status = CauseStatus.Closed;
        emit CauseClosed(causeId, cause.beneficiary);
    }

    function getAllCauses() public view returns (Cause[] memory) {
        Cause[] memory allCauses = new Cause[](causeCount);

        for (uint256 i = 1; i <= causeCount; i++) {
            allCauses[i - 1] = causes[i];
        }

        return allCauses;
    }
}
