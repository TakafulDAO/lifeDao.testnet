// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {TestDeployTakasure} from "test/utils/TestDeployTakasure.s.sol";
import {DeployConsumerMocks} from "test/utils/DeployConsumerMocks.s.sol";
import {HelperConfig} from "deploy/HelperConfig.s.sol";
import {TakasurePool} from "contracts/takasure/TakasurePool.sol";
import {TSToken} from "contracts/token/TSToken.sol";
import {BenefitMultiplierConsumerMock} from "test/mocks/BenefitMultiplierConsumerMock.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Reserve, Member, MemberState} from "contracts/types/TakasureTypes.sol";
import {IUSDC} from "test/mocks/IUSDCmock.sol";
import {SimulateDonResponse} from "test/utils/SimulateDonResponse.sol";

contract Join_TakasurePoolTest is StdCheats, Test, SimulateDonResponse {
    TestDeployTakasure deployer;
    DeployConsumerMocks mockDeployer;
    TakasurePool takasurePool;
    HelperConfig helperConfig;
    BenefitMultiplierConsumerMock bmConnsumerMock;
    address proxy;
    address contributionTokenAddress;
    address admin;
    IUSDC usdc;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    uint256 public constant USDC_INITIAL_AMOUNT = 100e6; // 100 USDC
    uint256 public constant CONTRIBUTION_AMOUNT = 25e6; // 25 USDC
    uint256 public constant BENEFIT_MULTIPLIER = 0;
    uint256 public constant YEAR = 365 days;
    uint256 public constant INITIAL_RESERVE_RATIO = 40;

    function setUp() public {
        deployer = new TestDeployTakasure();
        (, proxy, contributionTokenAddress, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        admin = config.daoMultisig;

        mockDeployer = new DeployConsumerMocks();
        bmConnsumerMock = mockDeployer.run();

        takasurePool = TakasurePool(address(proxy));
        usdc = IUSDC(contributionTokenAddress);

        // For easier testing there is a minimal USDC mock contract without restrictions
        deal(address(usdc), alice, USDC_INITIAL_AMOUNT);
        deal(address(usdc), bob, USDC_INITIAL_AMOUNT);

        vm.prank(alice);
        usdc.approve(address(takasurePool), USDC_INITIAL_AMOUNT);

        vm.prank(bob);
        usdc.approve(address(takasurePool), USDC_INITIAL_AMOUNT);

        vm.prank(admin);
        takasurePool.setNewBenefitMultiplierConsumer(address(bmConnsumerMock));

        vm.prank(msg.sender);
        bmConnsumerMock.setNewRequester(address(takasurePool));
    }

    /*//////////////////////////////////////////////////////////////
                                  JOIN
    //////////////////////////////////////////////////////////////*/

    /// @dev Test the contribution amount's last four digits are zero
    function testTakasurePool_contributionAmountDecimals() public {
        uint256 contributionAmount = 227123456; // 227.123456 USDC

        deal(address(usdc), alice, contributionAmount);

        vm.startPrank(alice);

        usdc.approve(address(takasurePool), contributionAmount);
        takasurePool.joinPool(contributionAmount, (5 * YEAR));

        vm.stopPrank();

        // We simulate a request before the KYC
        _successResponse(address(bmConnsumerMock));

        vm.prank(admin);
        takasurePool.setKYCStatus(alice);

        Reserve memory reserve = takasurePool.getReserveValues();
        uint256 totalContributions = reserve.totalContributions;

        Member memory member = takasurePool.getMemberFromAddress(alice);

        assertEq(member.contribution, 227120000); // 227.120000 USDC
        assertEq(totalContributions, member.contribution);
    }

    /*//////////////////////////////////////////////////////////////
                      JOIN POOL::CREATE NEW MEMBER
    //////////////////////////////////////////////////////////////*/

    /// @dev Test that the joinPool function updates the memberIdCounter
    function testTakasurePool_joinPoolUpdatesCounter() public {
        uint256 memberIdSlot = 23;
        bytes32 memberIdBytes32 = vm.load(address(takasurePool), bytes32(uint256(memberIdSlot)));
        uint256 memberIdCounterBeforeAlice = uint256(memberIdBytes32);

        vm.prank(alice);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        memberIdBytes32 = vm.load(address(takasurePool), bytes32(uint256(memberIdSlot)));
        uint256 memberIdCounterAfterAlice = uint256(memberIdBytes32);

        vm.prank(bob);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        memberIdBytes32 = vm.load(address(takasurePool), bytes32(uint256(memberIdSlot)));
        uint256 memberIdCounterAfterBob = uint256(memberIdBytes32);

        assertEq(memberIdCounterAfterAlice, memberIdCounterBeforeAlice + 1);
        assertEq(memberIdCounterAfterBob, memberIdCounterAfterAlice + 1);
    }

    modifier aliceKYCAndJoin() {
        vm.prank(admin);
        takasurePool.setKYCStatus(alice);

        // We simulate a request before the KYC
        _successResponse(address(bmConnsumerMock));

        vm.prank(alice);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));
        _;
    }

    /// @dev Test the membership duration is 5 years if allowCustomDuration is false
    function testTakasurePool_defaultMembershipDuration() public aliceKYCAndJoin {
        Member memory member = takasurePool.getMemberFromAddress(alice);

        assertEq(member.membershipDuration, 5 * YEAR);
    }

    /// @dev Test the member is created
    function testTakasurePool_newMember() public {
        vm.prank(alice);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        uint256 memberIdSlot = 23;
        bytes32 memberIdBytes32 = vm.load(address(takasurePool), bytes32(uint256(memberIdSlot)));
        uint256 memberId = uint256(memberIdBytes32);

        // Check the member is created and added correctly to mappings
        Member memory testMember = takasurePool.getMemberFromAddress(alice);

        assertEq(testMember.memberId, memberId);
        assertEq(testMember.benefitMultiplier, BENEFIT_MULTIPLIER);
        assertEq(testMember.contribution, CONTRIBUTION_AMOUNT);
        assertEq(testMember.wallet, alice);
        assertEq(uint8(testMember.memberState), 0);
    }

    modifier bobKYCAndJoin() {
        vm.prank(admin);
        takasurePool.setKYCStatus(bob);

        // We simulate a request before the KYC
        _successResponse(address(bmConnsumerMock));

        vm.prank(bob);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));
        _;
    }

    /// @dev More than one can join
    function testTakasurePool_moreThanOneJoin() public aliceKYCAndJoin bobKYCAndJoin {
        Member memory aliceMember = takasurePool.getMemberFromAddress(alice);
        Member memory bobMember = takasurePool.getMemberFromAddress(bob);

        Reserve memory reserve = takasurePool.getReserveValues();
        uint256 totalContributions = reserve.totalContributions;

        assertEq(aliceMember.wallet, alice);
        assertEq(bobMember.wallet, bob);
        assert(aliceMember.memberId != bobMember.memberId);

        assertEq(totalContributions, 2 * CONTRIBUTION_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                    JOIN POOL::UPDATE BOTH PRO FORMAS
    //////////////////////////////////////////////////////////////*/
    /// @dev Pro formas updated when a member joins
    function testTakasurePool_proFormasUpdatedOnMemberJoined() public aliceKYCAndJoin {
        vm.prank(admin);
        takasurePool.setKYCStatus(bob);

        Reserve memory reserve = takasurePool.getReserveValues();
        uint256 initialProFormaFundReserve = reserve.proFormaFundReserve;
        uint256 initialProFormaClaimReserve = reserve.proFormaClaimReserve;

        vm.prank(bob);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        reserve = takasurePool.getReserveValues();
        uint256 finalProFormaFundReserve = reserve.proFormaFundReserve;
        uint256 finalProFormaClaimReserve = reserve.proFormaClaimReserve;

        assert(finalProFormaFundReserve > initialProFormaFundReserve);
        assert(finalProFormaClaimReserve > initialProFormaClaimReserve);
    }

    /*//////////////////////////////////////////////////////////////
                         JOIN POOL::UPDATE DRR
    //////////////////////////////////////////////////////////////*/
    /// @dev New DRR is calculated when a member joins
    function testTakasurePool_drrCalculatedOnMemberJoined() public {
        Reserve memory reserve = takasurePool.getReserveValues();
        uint256 currentDRR = reserve.dynamicReserveRatio;

        vm.startPrank(admin);

        takasurePool.setKYCStatus(alice);
        takasurePool.setKYCStatus(bob);

        vm.stopPrank();

        // We simulate a request before the KYC
        _successResponse(address(bmConnsumerMock));

        vm.prank(alice);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        reserve = takasurePool.getReserveValues();
        uint256 aliceDRR = reserve.dynamicReserveRatio;

        vm.prank(bob);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        reserve = takasurePool.getReserveValues();
        uint256 bobDRR = reserve.dynamicReserveRatio;

        uint256 expectedAliceDRR = 48;
        uint256 expectedBobDRR = 44;

        assertEq(currentDRR, INITIAL_RESERVE_RATIO);
        assertEq(aliceDRR, expectedAliceDRR);
        assertEq(bobDRR, expectedBobDRR);
    }

    /*//////////////////////////////////////////////////////////////
                         JOIN POOL::UPDATE BMA
    //////////////////////////////////////////////////////////////*/
    /// @dev New BMA is calculated when a member joins
    function testTakasurePool_bmaCalculatedOnMemberJoined() public {
        Reserve memory reserve = takasurePool.getReserveValues();
        uint256 initialBMA = reserve.benefitMultiplierAdjuster;

        vm.startPrank(admin);

        takasurePool.setKYCStatus(alice);
        takasurePool.setKYCStatus(bob);

        vm.stopPrank();

        // We simulate a request before the KYC
        _successResponse(address(bmConnsumerMock));

        vm.prank(alice);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        reserve = takasurePool.getReserveValues();
        uint256 aliceBMA = reserve.benefitMultiplierAdjuster;

        vm.prank(bob);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        reserve = takasurePool.getReserveValues();
        uint256 bobBMA = reserve.benefitMultiplierAdjuster;

        uint256 expectedInitialBMA = 100;
        uint256 expectedAliceBMA = 90;
        uint256 expectedBobBMA = 88;

        assertEq(initialBMA, expectedInitialBMA);
        assertEq(aliceBMA, expectedAliceBMA);
        assertEq(bobBMA, expectedBobBMA);
    }

    /*//////////////////////////////////////////////////////////////
                        JOINPOOL::TOKENS MINTED
    //////////////////////////////////////////////////////////////*/
    /// @dev Test the tokens minted are staked in the pool
    function testTakasurePool_tokensMinted() public {
        uint256 daoTokenAddressSlot = 1;
        bytes32 daoTokenAddressSlotBytes = vm.load(
            address(takasurePool),
            bytes32(uint256(daoTokenAddressSlot))
        );
        address creditToken = address(uint160(uint256(daoTokenAddressSlotBytes)));
        TSToken creditTokenInstance = TSToken(creditToken);

        uint256 contractCreditTokenBalanceBefore = creditTokenInstance.balanceOf(
            address(takasurePool)
        );
        uint256 aliceCreditTokenBalanceBefore = creditTokenInstance.balanceOf(alice);

        vm.prank(admin);
        takasurePool.setKYCStatus(alice);

        // We simulate a request before the KYC
        _successResponse(address(bmConnsumerMock));

        vm.prank(alice);
        takasurePool.joinPool(CONTRIBUTION_AMOUNT, (5 * YEAR));

        uint256 contractCreditTokenBalanceAfter = creditTokenInstance.balanceOf(
            address(takasurePool)
        );
        uint256 aliceCreditTokenBalanceAfter = creditTokenInstance.balanceOf(alice);

        Member memory member = takasurePool.getMemberFromAddress(alice);

        assertEq(contractCreditTokenBalanceBefore, 0);
        assertEq(aliceCreditTokenBalanceBefore, 0);

        assertEq(contractCreditTokenBalanceAfter, CONTRIBUTION_AMOUNT * 10 ** 12);
        assertEq(aliceCreditTokenBalanceAfter, 0);

        assertEq(member.creditTokensBalance, contractCreditTokenBalanceAfter);
    }
}
