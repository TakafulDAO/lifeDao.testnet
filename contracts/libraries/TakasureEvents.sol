// SPDX-License-Identifier: GPL-3.0

/**
 * @title Events
 * @author  Maikel Ordaz
 * @notice  This library is used to store the events of the Takasure protocol
 */
import {RevenueType} from "contracts/types/TakasureTypes.sol";

pragma solidity 0.8.25;

library TakasureEvents {
    event OnMemberCreated(
        uint256 indexed memberId,
        address indexed member,
        uint256 indexed benefitMultiplier,
        uint256 contributionBeforeFee,
        uint256 serviceFee,
        uint256 membershipDuration,
        uint256 membershipStartTime
    ); // Emited when a new member is created
    event OnMemberUpdated(
        uint256 indexed memberId,
        address indexed member,
        uint256 indexed benefitMultiplier,
        uint256 contributionBeforeFee,
        uint256 serviceFee,
        uint256 membershipDuration,
        uint256 membershipStartTime
    ); // Emited when a member is updated. This is used when a member first KYCed and then paid the contribution
    event OnMemberJoined(uint256 indexed memberId, address indexed member);
    event OnMemberKycVerified(uint256 indexed memberId, address indexed member);
    event OnRecurringPayment(
        address member,
        uint256 indexed memberId,
        uint256 indexed lastPaidYearDate,
        uint256 indexed updatedContribution,
        uint256 updatedTotalServiceFee
    );
    event OnInitialReserveValues(
        uint256 indexed initialReserveRatio,
        uint256 dynamicReserveRatio,
        uint256 indexed benefitMultiplierAdjuster,
        uint256 indexed serviceFee,
        uint256 bmaFundReserveShare,
        bool isOptimizerEnabled,
        address contributionToken,
        address daoToken
    );
    event OnNewProFormaValues(
        uint256 indexed proFormaFundReserve,
        uint256 indexed proFormaClaimReserve
    );
    event OnNewReserveValues(
        uint256 indexed totalContributions,
        uint256 indexed totalClaimReserve,
        uint256 indexed totalFundReserve,
        uint256 totalFundExpenditures
    );
    event OnNewDynamicReserveRatio(uint256 indexed dynamicReserveRatio);
    event OnNewBenefitMultiplierAdjuster(uint256 indexed benefitMultiplierAdjuster);
    event OnRefund(uint256 indexed memberId, address indexed member, uint256 indexed amount);
    event OnBenefitMultiplierConsumerChanged(
        address indexed newBenefitMultiplierConsumer,
        address indexed oldBenefitMultiplierConsumer
    );
    event OnNewLossRatio(uint256 indexed lossRatio);
    event OnExternalRevenue(
        uint256 indexed newRevenueAmount,
        uint256 indexed totalRevenues,
        RevenueType indexed revenueType
    );
    event OnFundSurplusUpdated(uint256 indexed surplus);
    event OnMemberSurplusUpdated(uint256 indexed memberId, uint256 indexed surplus);
}
