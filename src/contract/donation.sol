// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Donation {
    enum CauseStatus {
        Open,
        Closed,
        Completed
    }

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
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Create a new cause.
     */
    function createCause(
        string memory name,
        address payable beneficiary,
        string memory description,
        uint256 goalAmount,
        string memory imageUrl
    ) public onlyOwner {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(goalAmount > 0, "Goal amount must be greater than zero");
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );

        require(bytes(imageUrl).length > 0, "Image URL cannot be empty");

        causeCount++;
        causes[causeCount] = Cause(
            name,
            description,
            beneficiary,
            goalAmount,
            0,
            0,
            CauseStatus.Open,
            imageUrl
        );
    }

    /**
     * @dev Make a donation to a cause.
     */
    function donate(uint256 causeId) public payable {
        Cause storage cause = causes[causeId];
        require(cause.status == CauseStatus.Open, "Cause is closed");
        require(msg.value > 0, "Donation amount must be greater than zero");
        uint256 remainingAmount = cause.goalAmount - cause.currentAmount;
        require(
            msg.value <= remainingAmount,
            "Donation amount exceeds the remaining goal amount"
        );

        cause.currentAmount += msg.value;
        emit DonationMade(causeId, msg.sender, msg.value);
        updateTopDonors(causeId, msg.sender, msg.value);
    }

    /**
     * @dev Get the top donors for a specific cause.
     */
    function getTopDonors(uint256 causeId)
        public
        view
        returns (TopDonor[] memory)
    {
        require(causeId <= causeCount, "Invalid cause ID");
        return topDonors[causeId];
    }

    /**
     * @dev Get the overall top donors.
     */
    function getOverallTopDonors() public view returns (TopDonor[] memory) {
        return overallTopDonors;
    }

    function sortTopDonors(uint256 causeId) internal {
        TopDonor[] storage causeDonors = topDonors[causeId];
        TopDonor[] storage allDonors = overallTopDonors;

        // Sort causeDonors
        uint256 causeDonorsLength = causeDonors.length;
        for (uint256 i = 0; i < causeDonorsLength - 1; i++) {
            for (uint256 j = 0; j < causeDonorsLength - i - 1; j++) {
                if (causeDonors[j].amount < causeDonors[j + 1].amount) {
                    TopDonor memory temp = causeDonors[j];
                    causeDonors[j] = causeDonors[j + 1];
                    causeDonors[j + 1] = temp;
                }
            }
        }

        uint256 allDonorsLength = allDonors.length;
        // Sort allDonors in ascending order of donation amount
        for (uint256 i = 0; i < allDonorsLength - 1; i++) {
            for (uint256 j = 0; j < allDonorsLength - i - 1; j++) {
                if (allDonors[j].amount < allDonors[j + 1].amount) {
                    TopDonor memory temp = allDonors[j];
                    allDonors[j] = allDonors[j + 1];
                    allDonors[j + 1] = temp;
                }
            }
        }
    }

    function getStructWithLowestAmount(uint256 causeId)
        internal
        view
        returns (uint256)
    {
        TopDonor[] storage causeDonors = topDonors[causeId];
        uint256 causeDonorsLength = causeDonors.length;

        require(causeDonorsLength > 0, "No donors found.");

        TopDonor memory lowestDonor = causeDonors[0];
        uint256 lowerDonorIndex = 1;

        for (uint256 i = 1; i < causeDonorsLength; i++) {
            if (causeDonors[i].amount < lowestDonor.amount) {
                lowestDonor = causeDonors[i];
                lowerDonorIndex = i;
            }
        }

        return lowerDonorIndex;
    }

    function getOverallStructWithLowestAmount()
        internal
        view
        returns (uint256)
    {
        TopDonor[] storage allDonors = overallTopDonors;

        uint256 causeDonorsLength = allDonors.length;

        require(causeDonorsLength > 0, "No donors found.");

        TopDonor memory lowestDonor = allDonors[0];
        uint256 lowerDonorIndex = 1;

        for (uint256 i = 1; i < causeDonorsLength; i++) {
            if (allDonors[i].amount < lowestDonor.amount) {
                lowestDonor = allDonors[i];
                lowerDonorIndex = i;
            }
        }

        return lowerDonorIndex;
    }

    function updateTopDonors(
        uint256 causeId,
        address donor,
        uint256 amount
    ) internal {
        TopDonor[] storage causeDonors = topDonors[causeId];
        TopDonor[] storage allDonors = overallTopDonors;
        bool addressExist = false;
        bool overallAddressExist = false;

        // Update causeDonors
        for (uint256 i = 0; i < causeDonors.length; i++) {
            if (causeDonors[i].donor == donor) {
                causeDonors[i].amount += amount;
                addressExist = true;
                break;
            }
        }

        if (!addressExist) {
            if (causeDonors.length < 10) {
                causeDonors.push(TopDonor(donor, amount));
            } else {
                uint256 lowestDonationIndex = getStructWithLowestAmount(
                    causeId
                );

                if (amount > causeDonors[lowestDonationIndex].amount) {
                    causeDonors[lowestDonationIndex] = TopDonor(donor, amount);
                }
            }
        }

        // Update allDonors
        for (uint256 i = 0; i < allDonors.length; i++) {
            if (allDonors[i].donor == donor) {
                allDonors[i].amount += amount;
                overallAddressExist = true;
                break;
            }
        }

        if (!overallAddressExist) {
            if (allDonors.length < 10) {
                allDonors.push(TopDonor(donor, amount));
            } else {
                uint256 lowestDonationIndex = getOverallStructWithLowestAmount();

                if (amount > allDonors[lowestDonationIndex].amount) {
                    allDonors[lowestDonationIndex] = TopDonor(donor, amount);
                }
            }
        }

        // Sort topDonors in ascending order of donation amount
        sortTopDonors(causeId);
    }

    /**
     * @dev Request a withdrawal of donated funds for a cause.
     */
    function requestDonation(uint256 causeId, uint256 amount) public onlyOwner {
        Cause storage cause = causes[causeId];
        require(cause.status == CauseStatus.Open, "Cause is closed");
        require(amount > 0, "Requested amount must be greater than zero");
        require(
            amount <= cause.currentAmount - cause.withdrawnAmount,
            "Requested amount exceeds the available funds"
        );

        cause.withdrawnAmount += amount;
        emit DonationReceived(causeId, msg.sender, amount);

        cause.beneficiary.transfer(amount);
    }

    /**
     * @dev Close a cause.
     */
    function closeCause(uint256 causeId) public {
        Cause storage cause = causes[causeId];
        require(causeId <= causeCount, "Invalid cause ID");
        require(
            cause.beneficiary == msg.sender,
            "Only beneficiary can close cause"
        );

        cause.status = CauseStatus.Closed;
        emit CauseClosed(causeId, cause.beneficiary);
    }

    /**
     * @dev Get all causes.
     */
    function getAllCauses() public view returns (Cause[] memory) {
        Cause[] memory allCauses = new Cause[](causeCount);

        for (uint256 i = 1; i <= causeCount; i++) {
            allCauses[i - 1] = causes[i];
        }

        return allCauses;
    }
}
