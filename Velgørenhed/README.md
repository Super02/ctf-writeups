# Writeup - Velgørenhed (Blockchain - Underflow & Reentrancy)
## We are presented with a link to a website that deploys a contract on the Ropsten testnet. We are given the source code to the smart contract and a contract address. Our goal is to empty the contract for funds.
![CTF objective](https://github.com/Super02/ctf-writeups/blob/main/Velg%C3%B8renhed/Screenshot%202022-05-10%20213040.png)
![Source code](https://github.com/Super02/ctf-writeups/blob/main/Velg%C3%B8renhed/Screenshot%202022-05-10%20213051.png)
We are first going to take a look at the smart contract to look for any potential vulnerabilities. When looking through the smart contract (We can also just use a tool like [slither](https://github.com/crytic/slither) to analyze the contract for us).
The function donateToContract has our interest.
```javascript
   function donateToContract(uint amount) public payable{
        require(amount <= donatorBalance[msg.sender], 'Insufficient balance');
        require(!donatedToContract[msg.sender], 'Can only donate to contract once!');
        donatedToContract[msg.sender]=true;
        charityBalance[address(this)] += amount;
        msg.sender.call{value: 0}("Thanks for your donation.");
        donatorBalance[msg.sender] -= amount;        
   }
```

The interesting part about this function is the two last lines. The function does a call before changing the donatorBalance variable. The solidity code is run synchronously, so the next line of code wont run untill the line before has fully executed. This can be exploited because we can setup a fallback function that runs when we receive the call from this function. We receive the call before our donator balance has changed. So in our fallback function we are able to run other functions in the smart contract before the donator balance is changed in the donateToContract function. If we execute the withdraw function before donator balance has been changed by donateToContract our donatorBalance will be 0 before donateToContract will subtract the amount. When we subtract something from 0 and we have an unsigned integer we will wrap around and create a underflow thus setting our donatorBalance to a very high value. 
Illustration:
![Illustration](https://github.com/Super02/ctf-writeups/blob/main/Velg%C3%B8renhed/Illustration.png)

#### Execution
To execute the smart contract functions we are going to use [Ethereum remix](https://remix.ethereum.org/). We are going to create two files. An attack.sol file and a file named charity.sol. The charity file contains the source code of the smart contract. While the attack.sol is something we have to write ourselves.

##### Creating attack.sol
Looking onlien we can find examples of reentrancy attacks. If we modify these examples we can use them here. We create a attack function that first executes the deposit function to deposit 0.1 ether. When we have deposited the ether we can then execute the vulnurable donateToContract function. We then have a fallback function that runs right before the donatorBalance is changed giving us an opportunity to withdraw our 0.1 ether. This leaves the donatorBalance at 0 untill after our fallback function is done executing as the donateToContract function executes the last line of code subtracting 0.1 ether from our donatorBalance which is 0. This create a underflow as 0 - 0.1 would be a negative value thus wrapping the unsigned integer around giving us a large donatorBalance.
```javascript
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
```

##### Withdraw
Now that our donatorBalance is a very high value we just use the withdraw function to withdraw. The withdraw function is set to withdraw all funds of the account even though we have a higher donatorBalance than the actual balance of the account.

##### Executing on the blockchain
To execute the attack function on the blockchain we need a wallet with Ropsten testnet ethereum. You can get testnet ethereum by using faucets on the internet. Then we are going to use metamask and connect it to ethereum remix by selecting injected web3. We then deploy our attack contract and execute the attack function with 0.1 ether. This will transact the attack on the Ropsten testnet and empty our contract.

#### Results
We have withdrawn the funds from the contract and we are left with an empty contract. This meets the goal set in the challenge. So we just go back and click on the button called "Check solved". This will give us our flag.
![Results](https://github.com/Super02/ctf-writeups/blob/main/Velg%C3%B8renhed/Screenshot%202022-05-10%20213021.png)
