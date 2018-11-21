pragma solidity ^0.4.4;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

contract Token
{
	/// @return total amount of tokens
	function totalSupply() public constant returns (uint256 supply) {}

	/// @param _owner The address from which the balance will be retrieved
	/// @return The balance
	function balanceOf(address _owner) constant returns (uint256 balance) {}

	/// @notice send `_value` token to `_to` from `msg.sender`
	/// @param _to The address of the recipient
	/// @param _value The amount of token to be transferred
	/// @return Whether the transfer was successful or not
	function transfer(address _to, uint256 _value) returns (bool success) {}

	/// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
	/// @param _from The address of the sender
	/// @param _to The address of the recipient
	/// @param _value The amount of token to be transferred
	/// @return Whether the transfer was successful or not
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

	/// @notice `msg.sender` approves `_addr` to spend `_value` tokens
	/// @param _spender The address of the account able to transfer the tokens
	/// @param _value The amount of wei to be approved for transfer
	/// @return Whether the approval was successful or not
	function approve(address _spender, uint256 _value) returns (bool success) {}

	/// @param _owner The address of the account owning tokens
	/// @param _spender The address of the account able to transfer the tokens
	/// @return Amount of remaining tokens allowed to spent
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token
{
	function transfer(address _to, uint256 _value) returns (bool success)
	{
		//Default assumes totalSupply can't be over max (2^256 - 1).
		//If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
		//Replace the if with this one instead.
		//if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
		if (balances[msg.sender] >= _value && _value > 0)
		{
			balances[msg.sender] -= _value;
			balances[_to] += _value;
			Transfer(msg.sender, _to, _value);
			return true;
		}
		else
		{
			return false;
		}
	}

	function transferFrom(address _from, address _to, uint256 _value) returns (bool success)
	{
		//same as above. Replace this line with the following if you want to protect against wrapping uints.
		//if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
		if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
			balances[_to] += _value;
			balances[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			Transfer(_from, _to, _value);
			return true;
		} else { return false; }
	}

	function balanceOf(address _owner) constant returns (uint256 balance)
	{
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) returns (bool success)
	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining)
	{
		return allowed[_owner][_spender];
	}

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	uint256 public totalSupply;

}

contract HelloWorldToken is StandardToken
{
    
    using SafeMath for uint256;

	/* Public variables of the token */

	/*
	NOTE:
	The following variables are OPTIONAL vanities. One does not have to include them.
	They allow one to customise the token contract & in no way influences the core functionality.
	Some wallets/interfaces might not even bother to look at this information.
	*/
	string public name;                                 // Token Name
	uint8 public decimals;                              // How many decimals to show. To be standard compliant keet it as 18
	string public symbol;                               // An identifier: eg BTC, ETH, SBX, XPR etc..
	string public version = '1.0';                      // Current Version
	uint256 public totalEthInWei;                       // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We'll store the total ETH raised via our ICO here.  
	address public fundsWallet;                         // Where should the raised ETH go?
	uint256 public stage;                               // stage
	uint256 public raisedAmount;                        // raised amount
	uint256 public availableTokens;                     // variable for check available tokens
	uint256 public tokensSold = 0;                      // sold tokens
	uint256 public buyPrice = 0.0001 ether;             // 1 BDQ = 0.0001 ETH or 1ETH = 10000 BDQ
	uint256 public constant softcap = 90000 ether;      // Soft Cap = 1200 TBD. Its constant and non-changeable number
	bool public softcapReached;                         // check for soft cap reached or not

	// This is a constructor function 
	// which means the following function name has to match the contract name declared above
	function HelloWorldToken()
	{
	    
		totalSupply 		    = 1000000000000000000000000000;     // total supply, 	1 Billion Tokens
		name 				    = "BDAQ Token";                     // name for display purposes
		symbol 				    = "BDAQ";                           // symbol for display purposes
		decimals 			    = 18;                               // Amount of decimals for display purposes
		
		// token holder
		fundsWallet 		    = msg.sender;
		
		// balance distribute
		balances[fundsWallet]   = totalSupply;              // 100% to owner
		
		stage = 1;                                          // initialize ico stage
		raisedAmount = 0;
		availableTokens = totalSupply;                      // initialize available tokens 
		
	}
	
	event CrowdStarted(uint256 tokens, uint256 startDate, uint256 endDate, uint256 bonus);
	event SoftcapReached();
    
    modifier onlyOwner() {
        require(msg.sender == fundsWallet);
        _;
    }
    
    mapping(address => Contributor) public contributors;
    
    struct Contributor {
        uint256 eth;                        // ETH on this wallet 
        bool whitelisted;                   // White listed true/false
        uint256 ethHistory;                 // All deposited ETH history
        uint256 tokensPurchasedDuringICO;   // Tokens puchuased during ICO
        uint256 bonusGetDuringPrivateSale;  // Bonus purchuased during private sale
    }
    
    struct Ico {
        uint256 tokens;    // Tokens in crowdsale
        uint256 startDate; // Date when crowsale will be starting, after its starting that property will be the 0
        uint256 endDate;   // Date when crowdsale will be stop
        uint256 bonus;  // Bonus
    }

    Ico public ICO;
	
	function startCrowd(uint256 _tokens, uint256 _startDate, uint256 _endDate, uint256 _bonus) public onlyOwner {
	    uint icoTokens = ((totalSupply).mul(_tokens)).div(100);  // Vivek Why Div by 100 ??
        require(icoTokens <= availableTokens);
        require(_startDate < _endDate);

        ICO = Ico(icoTokens, _startDate, _endDate, _bonus); // _startDate + _endDate * 1 days
        stage = stage.add(1);

        CrowdStarted(icoTokens, _startDate, _endDate, _bonus);
    }

	function() external payable  // Vivek This is one time function right ??
	{
	    
        require(ICO.startDate <= now);
        require(ICO.endDate > now);
        require(ICO.tokens >= 0);

        _secureChecks(msg.sender);
		
	}
	
	function _secureChecks(address _address) internal {
        require(_address != address(0));
        require(msg.value >= 0);
        //require(msg.value >= ( 1 ether / 100)); // minimum buy amount in ether 0.01  // Vivek  --> 1 ETH = 10000 BDAQ so min amount should be .1 ETH as 1000 BDQ is min qty
        
        _deliverTokens(msg.sender);
    }

    function _deliverTokens(address _address) internal {
        Contributor storage contributor = contributors[_address];

        uint256 amountEth = contributor.eth;
        uint256 amountToken = _getTokenAmount(amountEth);

        require(amountToken > 0);
        require(_confirmSell(amountToken));
        
        contributor.eth = 0;
        contributor.tokensPurchasedDuringICO = (contributor.tokensPurchasedDuringICO).add(amountToken);
        
        tokensSold = tokensSold.add(amountToken);
        availableTokens = availableTokens.sub(amountToken);
        ICO.tokens = ICO.tokens.sub(amountToken);

        // token.transfer(_contributor, amountToken); To change

        if ((tokensSold >= softcap) && !softcapReached) {
            softcapReached = true;
            SoftcapReached();
        }

    }
    
    function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
        require(_weiAmount > 0);
        
        uint256 weiAmount = (_weiAmount * 1 ether).div(buyPrice);
        require(weiAmount > 0);
        
        weiAmount = weiAmount.add(_withBonus(weiAmount, ICO.bonus));
        return weiAmount;
    }
    
    function _withBonus(uint256 _amount, uint256 _percent) internal pure returns(uint256) { 
        require(_amount > 0);

        return (_amount.mul(_percent)).div(100); // Vive add bonus to qty purchuased is you buy 1000 BDQ then 300 are free 30%
    }
    
    function _confirmSell(uint256 _amount) internal view returns(bool) {
        if (ICO.tokens < _amount) {
            return false;
        }

        return true;
    }
	
	function getRaisedAmount() public onlyOwner constant returns (uint) {
	    return raisedAmount;
	}

	/* Approves and then calls the receiving contract */
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success)
	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);

		//call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
		//receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
		//it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
		if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
		return true;
	}
	
	/* check crowd sale status */
    function crowdSaleStatus() public constant returns(string) {
        
        if (1 == stage) {
            return "Stage 1";
        } else if(2 == stage) {
            return "Stage 2";
        } else if(3 == stage) {
            return "Stage 3";
        } else if(4 == stage) {
            return "Stage 4";
        }

        return "Crowdsale finished!";
    }
	
}