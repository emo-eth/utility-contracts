// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {TwoStepOwnable} from "utility-contracts/TwoStepOwnable.sol";

contract TwoStepAdministered is TwoStepOwnable {
    event AdministratorUpdated(
        address indexed user,
        address indexed newAdministrator
    );
    event PotentialAdministratorUpdated(address newPotentialAdministrator);

    error OnlyAdministrator();
    error OnlyOwnerOrAdministrator();
    error NotNextAdministrator();
    error AlreadyInitialized();
    error NewAdministratorIsZeroAddress();

    address public administrator;
    address public potentialAdministrator;

    modifier onlyAdministrator() virtual {
        if (msg.sender != administrator) {
            revert OnlyAdministrator();
        }

        _;
    }

    modifier onlyOwnerOrAdministrator() virtual {
        if (msg.sender != owner()) {
            if (msg.sender != administrator) {
                revert OnlyOwnerOrAdministrator();
            }
        }
        _;
    }

    constructor(address _administrator) {
        administrator = _administrator;

        emit AdministratorUpdated(address(0), _administrator);
    }

    function _initialize(address _administrator) public {
        if (address(this).code.length != 0) {
            revert AlreadyInitialized();
        }
        administrator = _administrator;

        emit AdministratorUpdated(address(0), _administrator);
    }

    function transferAdministration(address newAdministrator)
        public
        virtual
        onlyAdministrator
    {
        if (newAdministrator == address(0)) {
            revert NewAdministratorIsZeroAddress();
        }
        potentialAdministrator = newAdministrator;
        emit PotentialAdministratorUpdated(newAdministrator);
    }

    function _transferAdministration(address newAdministrator)
        internal
        virtual
    {
        administrator = newAdministrator;

        emit AdministratorUpdated(msg.sender, newAdministrator);
    }

    ///@notice Claim administration of smart contract, after the current administrator has initiated the process with transferAdministration
    function acceptAdministration() public virtual {
        address _potentialAdministrator = potentialAdministrator;
        if (msg.sender != _potentialAdministrator) {
            revert NotNextAdministrator();
        }
        _transferAdministration(_potentialAdministrator);
        delete potentialAdministrator;
    }

    ///@notice cancel administration transfer
    function cancelAdministrationTransfer() public virtual onlyAdministrator {
        delete potentialAdministrator;
        emit PotentialAdministratorUpdated(address(0));
    }

    function renounceAdministration() public virtual onlyAdministrator {
        delete administrator;
        emit AdministratorUpdated(msg.sender, address(0));
    }
}
