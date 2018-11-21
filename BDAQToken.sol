pragma solidity ^0.4.21;

import "./StandardToken.sol";

contract BDAQToken is StandardToken
{

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    uint256 public totalSupply;                         // Total token supply
    string public name;                                 // Token Name
    uint8 public decimals;                              // How many decimals to show. To be standard complicant keep it 18
    string public symbol;                               // An identifier: eg SBX, XPR etc..
    string public version = '1.0';                      // versioning
    uint256 public totalEthInWei;                       // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We'll store the total ETH raised via our ICO here.  
    address public fundsWallet;                         // Where should the raised ETH go?
    uint256 public stage;                               // stage
    uint256 public raisedAmount;                        // raised amount
    uint256 public availableTokens;                     // variable for check available tokens
    uint256 public tokensSold = 0;                      // sold tokens
    uint256 public buyPrice = 0.0001 ether;             // 1 BDQ = 0.001ETH or 1ETH = 10000BDQ
    uint256 public constant softcap = 90000 ether;      // Soft Cap = 90000 ether. Its constant and non-changeable number
    bool public softcapReached;                         // check for soft cap reached or not

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    constructor() public 
    {
        
        totalSupply             = 1000000000000000000000000000;     // total supply
        name                    = "BDAQ Token";                     // name for display purposes
        symbol                  = "BDAQ";                           // symbol for display purposes
        decimals                = 18;                               // Amount of decimals for display purposes
        
        // token holder
        fundsWallet             = msg.sender;
        
        // balance distribute
        balances[fundsWallet]   = totalSupply;              // 100% to owner
        
        stage = 0;                                          // initialize ico stage
        raisedAmount = 0;
        availableTokens = totalSupply;                      // initialize available tokens 
        
        startCrowd(30, 1525132800, 1525910400, 10);
        
    }
    
    event CrowdStarted(uint256 tokens, uint256 startDate, uint256 endDate, uint256 bonus);
    event SoftcapReached();
    
    modifier onlyOwner() {
        require(msg.sender == fundsWallet);
        _;
    }
    
    struct Ico {
        uint256 tokens;    // Tokens in crowdsale
        uint256 startDate; // Date when crowsale will be starting, after its starting that property will be the 0
        uint256 endDate;   // Date when crowdsale will be stop
        uint256 discount;  // Bonus
    }

    Ico public ICO;
    
    function startCrowd(uint256 _tokens, uint256 _startDate, uint256 _endDate, uint256 _discount) public onlyOwner {
        uint icoTokens = ((totalSupply).mul(_tokens)).div(100);
        require(icoTokens <= availableTokens);
        require(_startDate < _endDate);

        ICO = Ico(icoTokens, _startDate, _endDate, _discount); // _startDate + _endDate * 1 days
        stage = stage.add(1);

        emit CrowdStarted(icoTokens, _startDate, _endDate, _discount);
    }

    function() public payable
    {
        require(ICO.startDate <= now);
        require(ICO.endDate > now);
        require(ICO.tokens > 0);
        
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = (msg.value * 1 ether).div(buyPrice);

        if (balances[fundsWallet] < amount)
        {
            return;
        }
        
        require(amount > 0);
        require(_confirmSell(amount));

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        emit Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain
        
        tokensSold = tokensSold.add(amount);
        availableTokens = availableTokens.sub(amount);
        ICO.tokens = ICO.tokens.sub(amount);

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
        
        raisedAmount += msg.value;

        if ((tokensSold >= softcap) && !softcapReached) {
            softcapReached = true;
            emit SoftcapReached();
        }
        
    }
    
    function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
        require(_weiAmount > 0);
        
        uint256 weiAmount = (_weiAmount * 1 ether).div(buyPrice);
        require(weiAmount > 0);
        
        weiAmount = weiAmount.add(_withBonus(weiAmount, ICO.discount));
        return weiAmount;
    }
    
    function _withBonus(uint256 _amount, uint256 _percent) internal pure returns(uint256) {
        require(_amount > 0);

        return (_amount.mul(_percent)).div(100);
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
    
    /* check crowd sale status */
    function crowdSaleStatus() public constant returns(string) {
        
        if (0 == stage) {
            return "Sale not started";
        } else if (1 == stage) {
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