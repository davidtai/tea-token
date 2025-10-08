// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Create2 } from "@openzeppelin/utils/Create2.sol";
import { console2 } from "forge-std/console2.sol";

import { Tea } from "../src/TeaToken/Tea.sol";
import { TokenDeploy } from "../src/TeaToken/TokenDeploy.sol";
import { MintManager } from "../src/TeaToken/MintManager.sol";
import { DeterministicDeployer } from "../src/utils/DeterministicDeployer.sol";

/* solhint-disable max-states-count */
contract TokenDeployTestMiner is PRBTest, StdCheats {
    TokenDeploy internal tokenDeploy;
    bytes32 internal teaCodeHash;
    bytes32 internal mintManagerCodeHash;

    // Multisig
    // address internal multiSig = 0x5D435ac154d9188621275998dAB6249Fac149C41;
    // address internal multiSig = 0x2e20f31d47Fe7Aa111dCC67Cb0eC6A411254Ae6e;
    address internal multiSig = 0xcDb68686290310dD8623371E1db53157dB6b8cA1;
    // new Tea
    // address internal newTea = 0x7eaA67f8D365BBe27D6278fDc2ba24a1aa71C8e5;
    // address internal newTea = 0x7Eaa8557E1A608bcc77C2d392093cE7F05c0DB14;
    address internal newTea = 0x7eA1eB95D4C7463462223C714d310F919c1B1214;
    // deploy salt
    // bytes32 internal deploySalt = 0x000000000000000000000000000000000000000000ffffffaaaaabbbbbbbbbbb;
    bytes32 internal deploySalt = 0x00000000000000000000000000000000000000ffffffffffaaaaabbbbbbbcccc;

    error Unauthorized();
    error AlreadyDeployed();

    function setUp() public virtual {
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 23_528_504 });
        tokenDeploy = TokenDeploy(
            DeterministicDeployer._deploy(deploySalt, type(TokenDeploy).creationCode, abi.encode(multiSig))
        );
        teaCodeHash = keccak256(abi.encodePacked(type(Tea).creationCode, abi.encode(address(tokenDeploy))));
        mintManagerCodeHash =
            keccak256(abi.encodePacked(type(MintManager).creationCode, abi.encode(multiSig, newTea)));
        // deploy salt

        assertEq(six_bytes(multiSig), 0xcDb);
        assertEq(six_bytes(newTea), 0x7ea);
        console2.logAddress(address(tokenDeploy));
        console2.logAddress(multiSig);
        console2.logBytes32(teaCodeHash);
        console2.logBytes32(mintManagerCodeHash);
    }

    function testFuzz_mine_token_salt(bytes32 salt) public view {
        address _tea = Create2.computeAddress(salt, teaCodeHash, address(tokenDeploy));
        // check the first six bytes are 0x7ea
        if (six_bytes(_tea) == 0x7ea) {
            console2.logAddress(_tea);
            console2.logBytes32(salt);
            revert Unauthorized();
        }
    }

    function testFuzz_mine_manager_salt(bytes32 salt) public view {
        address _mintManager = Create2.computeAddress(salt, mintManagerCodeHash, address(tokenDeploy));
        // check the first six bytes are 0x7ea
        if (six_bytes(_mintManager) == 0x7ea) {
            console2.logAddress(_mintManager);
            console2.logBytes32(salt);
            revert Unauthorized();
        }
    }

    function six_bytes(address _address) public pure returns (uint32) {
        return uint32(uint160(_address) >> 148);
    }
}
