// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Create2 } from "@openzeppelin/utils/Create2.sol";

import { Tea } from "../src/TeaToken/Tea.sol";
import { MintManager } from "../src/TeaToken/MintManager.sol";

/* solhint-disable max-states-count */
contract TokenDeployTestMiner is PRBTest, StdCheats {
    bytes32 internal teaCodeHash;
    bytes32 internal mintManagerCodeHash;

    address internal initialGovernor = address(vm.envAddress("INITIAL_GOVERNOR"));

    error Unauthorized();
    error AlreadyDeployed();

    function setUp() public virtual {
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 20_456_340 });
        teaCodeHash = keccak256(abi.encodePacked(type(Tea).creationCode, abi.encode(initialGovernor)));
        mintManagerCodeHash = keccak256(abi.encodePacked(type(MintManager).creationCode, abi.encode(initialGovernor)));

        assertEq(six_bytes(initialGovernor), 0xFD4);
    }

    function testFuzz_mine_token_salt(bytes32 salt) public {
        address _tea = Create2.computeAddress(salt, teaCodeHash, initialGovernor);
        // check the first six bytes are 0x7ea
        assertNotEq(six_bytes(_tea), 0x7ea);
    }

    function testFuzz_mine_manager_salt(bytes32 salt) public {
        address _mintManager = Create2.computeAddress(salt, mintManagerCodeHash, initialGovernor);
        // check the first six bytes are 0x7ea
        assertNotEq(six_bytes(_mintManager), 0x7ea);
    }

    function six_bytes(address _address) public pure returns (uint32) {
        return uint32(uint160(_address) >> 148);
    }
}
