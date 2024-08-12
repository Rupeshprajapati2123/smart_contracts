// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
pragma solidity ^0.8.26;

contract ApproverToken is ERC20{ 
    address public owner;
    mapping(address => bool) public approvedApprovers;
    mapping(address => bool) public appliedForApprovals;
    uint approverCount;
    uint transactionCount;
    event AppliedForApproval(address applied);
    event Approved(address approved);
    event DeletedApprover(address deleted);
    event TransactionCreated(uint256 transactionId, address from, address to, uint256 amount);
    event TransactionApproved(uint256 transactionId, address approver);
    event TransactionExecuted(uint256 transactionId);
    struct Transaction{
        address from;
        address to;
        uint amount;
        uint approvalCount;
        mapping (address=> bool) approvals;
        bool executed;
    }
    mapping(uint256 => Transaction) public transactions;
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol){
        owner=msg.sender;
        approvedApprovers[msg.sender]=true;
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    modifier onlyApprover(){
        require(approvedApprovers[msg.sender],"Only approvers can execute this function");
        _;
    }
    function createTransaction(address _to, uint _amount) external{
        require(balanceOf(msg.sender)>=_amount,"You don't have enough tokens");
        uint transactionId=transactionCount;
        Transaction storage newTransaction=transactions[transactionId];
        newTransaction.from=msg.sender;
        newTransaction.to=_to;
        newTransaction.amount=_amount;
        newTransaction.approvalCount=0;
        newTransaction.executed=false;
        
        transactionCount++;
        emit TransactionCreated(transactionId, msg.sender, _to, _amount);
    }

    function approveTransaction(uint _transactionId) external onlyApprover{
        Transaction storage transaction= transactions[_transactionId];
        require(!transaction.executed,"Transaction already executed");
        require(!transaction.approvals[msg.sender], "Transaction already approved by this approver");

        transaction.approvals[msg.sender]=true;
        transaction.approvalCount++;

        emit TransactionApproved(_transactionId, msg.sender);
        if(transaction.approvalCount>approverCount/2){
            executeTransaction(_transactionId);
        }
    }

    function executeTransaction(uint _transactionId) internal {
        Transaction storage transaction = transactions[_transactionId];
        require(!transaction.executed,"Transaction already executed");
        require(transaction.approvalCount> approverCount/2,"Insufficient Approvals");

        transaction.executed=true;
        _transfer(transaction.from, transaction.to, transaction.amount);

        emit TransactionExecuted(_transactionId);
    }
    function applyForApproval() public{
        require(!approvedApprovers[msg.sender],"You are already approved");
        require(!appliedForApprovals[msg.sender], "You have already applied");

        appliedForApprovals[msg.sender]=true;
        emit AppliedForApproval(msg.sender);
    }
    function approveApprovall(address toBeApproved) public{
        require(!approvedApprovers[toBeApproved],"The Address is already approved");
        approvedApprovers[toBeApproved] = true;
        approverCount++;
        delete appliedForApprovals[toBeApproved];
        emit Approved(toBeApproved);
    }
    function deleteApprover(address toBeDeleted) public{
        require(approvedApprovers[toBeDeleted],"Address Not Found");
        approverCount--;
        delete(approvedApprovers[toBeDeleted]);
        emit DeletedApprover(toBeDeleted);
    }
    
}