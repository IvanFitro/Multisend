// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

// @title <Multisend.sol>
/// @author <IvanFitro>
/* @notice <Creation of an smart contract that pays every hour to all of the employees with one transaction. 
            You can contract/dismiss employees, modify the salary per hour, add divisions for group all the employees,
            see all the employees for each division>
*/

contract Multisend {
    
    //Instance for the token contract 
    ERC20 private token;
    //State variables
    address payable public owner;
    uint salary;
    uint maxLength;



    constructor()  {
        token = new ERC20(100000);
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You don't have permisions");
        _;
    }

    struct employee {
        address direction;
        uint time;
        uint tokens;
    }


    //Mapping to relationate the name of the division for each employee
    mapping (string => employee []) public Employees;

    //Events
    event sendedTokens(uint, uint);
    event newEmployee(string, address);

    //Function to contract a employee
    function Contract(string memory _division, address _address) public onlyOwner {
        Employees[_division].push(employee(_address, block.timestamp, 0));
        emit newEmployee(_division, _address);
    }

    //Function to dismiss a employee
    function Dismiss(string memory _division, address _address) public onlyOwner returns(bool) {
        uint i = 0;
        //Scan the array to search the direction of the employee
        for (i; i <= Employees[_division].length -1; i++) {
            if (Employees[_division][i].direction == _address) {
                 //Put the selected id to the last position to remove
                Employees[_division][i] = Employees[_division][Employees[_division].length - 1];
                //Delete the last postion
                Employees[_division].pop();
                return true;
            }
        }
        return false;
    }

    //Function to set the salary per hour
    function setSalary(uint _tokens) public onlyOwner {
        salary = _tokens;
    }

    //Function to set the maxium length of the array for each division (for avoid infinite loops)
    function setMaxLength(uint _maxLength) public onlyOwner {
        maxLength = _maxLength;
    }

    //Function to see the balance of the smart contract
    function balanceOf() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    //Function to see all the employees of a division
    function seeDivision(string memory _division) public view returns(employee [] memory) {
        return Employees[_division];
    }

    //Function to see the tokens that a employee has
    function myTokens() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    //Function to claim the tokens for each employee
    function claimTokens(string memory _division) public onlyOwner {
        require(Employees[_division].length -1 <= maxLength, "The array is too long");
        uint i=0;

        for (i; i <= Employees[_division].length -1; i++) {
            //How long the employee has worked
            uint timeWorked = block.timestamp - Employees[_division][i].time;
            //See how many time the employee has work
            if (timeWorked >= 1 hours) {
                //Save the tokens that correspond for this employee
                Employees[_division][i].tokens += salary * timeWorked/3600;
                //Reset the work time
                Employees[_division][i].time = block.timestamp;
            }
        }
    }

    //Function to send all the tokens for each employee
    function multiSend(string memory _division) public onlyOwner {
        require(Employees[_division].length -1 <= maxLength, "The array is too long");
        uint i = 0;
        uint total = 0;

        for (i; i <= Employees[_division].length -1; i++) {
            //Comprove that the smart contract have enough funds
            require(balanceOf() > 0, "Insufficient funds");
            //Send the tokens to the employee
            token.MultisendTransfer(address(this), Employees[_division][i].direction, Employees[_division][i].tokens);
            total += Employees[_division][i].tokens;
            //Reset the tokens of the employee
            Employees[_division][i].tokens = 0;
        }
        emit sendedTokens(total, Employees[_division].length);
    }

}