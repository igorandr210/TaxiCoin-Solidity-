pragma solidity ^0.4.23;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";



contract Escrow is Ownable,StandardToken {
    
string public name = 'TaxiCoin';
string public symbol = 'TXC';
uint8 public decimals = 0;
uint public INITIAL_SUPPLY = 120000;
    enum PaymentStatus { Pending, Completed, Refunded,GetByExecutor }
    event PaymentCreation(uint indexed orderId, address indexed customer, uint value);
    event PaymentCompletion(uint indexed orderId, address indexed customer, uint value, PaymentStatus status);

    struct Payment {
        address customer;
        address executor; 
        uint value;
        PaymentStatus status;
        bool refundApproved;
        bool isValue;
    }
    mapping(uint => Payment) public payments;
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function createPayment(uint _orderId, uint _value) external {
        require(!payments[_orderId].isValue);
        bool result=transfer(owner,_value);
        require(result);
        payments[_orderId] = Payment(msg.sender,address(0), _value, PaymentStatus.Pending, false,true);
        emit PaymentCreation(_orderId, msg.sender, _value);
    }
    function getOrder(uint _orderId) external {
        Payment storage payment = payments[_orderId];
        require(payment.executor==address(0));
        require(payment.status==PaymentStatus.Pending);
        payment.status=PaymentStatus.GetByExecutor;
        payment.executor=msg.sender;
    }
 
    function completeOrder(uint _orderId) external{
        Payment storage payment = payments[_orderId];
        require(payment.customer==msg.sender);
        require(payment.status==PaymentStatus.GetByExecutor);
        transfer(payment.executor,payment.value);
        payment.status=PaymentStatus.Completed;
    }

    function refund(uint _orderId) external {
        Payment storage payment = payments[_orderId];
        require(payment.status==PaymentStatus.Pending||payment.status==PaymentStatus.GetByExecutor);
        require(payment.customer==msg.sender);
        payment.status=PaymentStatus.Refunded;
    }

    function approveRefund(uint _orderId) external onlyOwner{
        Payment storage payment = payments[_orderId];
        require(payment.refundApproved==false);
        bool res=transfer(payment.customer,payment.value);
        require(res);
        payment.refundApproved = true;
    }
}
