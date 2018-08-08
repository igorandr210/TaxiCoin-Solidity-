pragma solidity ^0.4.23;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";



contract Escrow is Ownable,StandardToken {
    
    string public name = 'TaxiCoin';
    string public symbol = 'TXC';
    uint8 public decimals = 0;
    uint public INITIAL_SUPPLY = 120000;
    enum PaymentStatus { Pending, Completed, Refunded,GetByDriver }
    uint Comission=0;


    struct Payment {
        address Customer;
        address Driver; 
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

    function setComission(uint _newComission) external onlyOwner returns(uint)
    {
        require(_newComission<100);
        require(_newComission>0);
        Comission=_newComission;
        return Comission;
    }

    function createPayment(uint _orderId, uint _value) external returns(uint) {
        require(!payments[_orderId].isValue);
        require(balances[msg.sender]>=_value);
        balances[msg.sender]-=_value;
        balances[owner]+=_value;
        payments[_orderId] = Payment(msg.sender,address(0), _value, PaymentStatus.Pending, false,true);
        return uint(PaymentStatus.Pending);
    }
    function getOrder(uint _orderId) external returns(uint) {
        Payment storage payment = payments[_orderId];
        require(payment.Driver==address(0));
        require(payment.status==PaymentStatus.Pending);
        payment.status=PaymentStatus.GetByDriver;
        payment.Driver=msg.sender;
        return uint(payment.status);
    }
 
    function completeOrder(uint _orderId) external returns(uint){
        Payment storage payment = payments[_orderId];
        require(payment.Customer==msg.sender);
        require(payment.status==PaymentStatus.GetByDriver);
        require(balances[owner]>=payment.value);
        uint comissionValue=(payment.value*Comission)/100;
        balances[owner]-=(payment.value-comissionValue);
        balances[payment.Driver]+=(payment.value-comissionValue);
        payment.status=PaymentStatus.Completed;
        return uint(payment.status);
    }

    function refund(uint _orderId) external returns(uint){
        Payment storage payment = payments[_orderId];
        require(payment.status==PaymentStatus.Pending||payment.status==PaymentStatus.GetByDriver);
		require(payment.Customer==msg.sender);
		if(payment.status==PaymentStatus.Pending)
		{
            require(balances[owner]>=payment.value);
            balances[owner]-=payment.value;
            balances[payment.Customer]+=payment.value;
			payment.refundApproved = true;
			payment.status=PaymentStatus.Completed;
			return uint(payment.status);
		}
		else
		{
			payment.status=PaymentStatus.Refunded;
			return uint(payment.status);
		}
    }
	
	function disApproveRefund(uint _orderId) external onlyOwner returns(uint){
        Payment storage payment = payments[_orderId];
        require(payment.refundApproved==false);
		require(payment.status==PaymentStatus.Refunded);
        require(balances[owner]>=payment.value);
        balances[owner]-=payment.value;
        balances[payment.Driver]+=payment.value;
        payment.status=PaymentStatus.Completed;
        return uint(payment.status);
    }
	
    function approveRefund(uint _orderId) external onlyOwner returns(uint){
        Payment storage payment = payments[_orderId];
        require(payment.refundApproved==false);
		require(payment.status==PaymentStatus.Refunded);
        require(balances[owner]>=payment.value);
        balances[owner]-=payment.value;
        balances[payment.Customer]+=payment.value;
        payment.refundApproved = true;
        payment.status=PaymentStatus.Completed;
        return uint(payment.status);
    }

    function deposit() external payable returns(uint) {
        require(msg.value>0);
        totalSupply_+=msg.value;
        balances[msg.sender] += msg.value;
		return balances[msg.sender];
    } 
}
