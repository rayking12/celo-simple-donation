// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Donation {

   struct Cause {
    string name;
    string description;
    address payable beneficiary;
    uint256 goalAmount;
    uint256 currentAmount;
    uint256 withdrawnAmount;
    bool closed;
    string imageUrl;
   }

    struct TopDonor {
        address donor;
        uint256 amount;
    }


    mapping(uint256 => Cause) public causes;
    mapping(uint256 => TopDonor[]) public topDonors;
     TopDonor[] public overallTopDonors; // Overall top donors
    uint256 public causeCount;

    event DonationMade(uint256 causeId, address donor, uint256 amount);
    event DonationReceived(uint256 causeId, address donor, uint256 amount);

    function createCause(string memory name, address payable beneficiary, string memory description, uint256 goalAmount, string memory imageUrl) public {
        causeCount++;    
    
        causes[causeCount] = Cause(name, description, beneficiary, goalAmount, 0, 0, false, imageUrl);
    }

      function donate(uint256 causeId) public payable {
        Cause storage cause = causes[causeId];
        require(!cause.closed, "Cause is closed");

        cause.currentAmount += msg.value;
        emit DonationMade(causeId, msg.sender, msg.value);

        updateTopDonors(causeId, msg.sender, msg.value);
    }

   function getTopDonors(uint256 causeId) public view returns (TopDonor[] memory) {
        return topDonors[causeId];
    }

    function getOverallTopDonors() public view returns (TopDonor[] memory) {
        return overallTopDonors;
    }
function updateTopDonors(
    uint256 causeId,
    address donor,
    uint256 amount
) internal {
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
        require(!cause.closed, "Cause is closed");

        cause.beneficiary.transfer(amount);
        cause.withdrawnAmount += amount;
        emit DonationReceived(causeId, msg.sender, amount);
    }



    function closeCause(uint256 causeId) public {
        Cause storage cause = causes[causeId];
        require(cause.beneficiary == msg.sender, "Only beneficiary can close cause");

        cause.closed = true;
    }
    
    function getAllCauses() public view returns (Cause[] memory) {
    Cause[] memory allCauses = new Cause[](causeCount);

    for (uint256 i = 1; i <= causeCount; i++) {
        allCauses[i - 1] = causes[i];
    }

    return allCauses;
}
}