# Writeup
We are presented with a link to a website that deploys a contract on the Ropsten testnet. We are given the source code to the smart contract and a contract address. Our goal is to empty the contract for funds.
[[/Screenshot 2022-05-10 213040.png|CTF objective]]

We are first going to take a look at the smart contract to look for any potential vulnurabilites. 
[[/Screenshot 2022-05-10 213051.png|Source code]]
When looking through the smart contract (either by hand or by using a tool like slither) you may notice the function donateToContract.
```sol
   function donateToContract(uint amount) public payable{
        require(amount <= donatorBalance[msg.sender], 'Insufficient balance');
        require(!donatedToContract[msg.sender], 'Can only donate to contract once!');
        donatedToContract[msg.sender]=true;
        charityBalance[address(this)] += amount;
        msg.sender.call{value: 0}("Thanks for your donation.");
        donatorBalance[msg.sender] -= amount;        
   }
```

What is interesting about this function is that it does a call before setting the donaterBalance. This allows us to create a fallback that executes code and changes the state of the contract before the last line of code is executed in the function. The idea behind this is to change donatorBalance to a value lower than the variable amount. Doing this will create a underflow. And since donatorBalance is a uint (unsigned integer) it will wrap around giving us an insanely high donatorBalance.

#### Withdraw
Now that our donatorBalance is a very high value we just use the withdraw function to withdraw. The withdraw function is set to withdraw all funds of the account even though we have a higher donatorBalance than the actual balance of the account.

#### Results
When we have withdrawn the funds from the contract we are left with an empty contract. This meets the goal set in the challenge. So we just go back and click on the button called "Check solved". This will give us our flag.
[[/Screenshot 2022-05-10 213040.png|Source code]]
