// Bond Film Platform tokensale smart contract.
// Developed by Phenom.Team <info@phenom.team>
pragma solidity ^0.4.18;

/**
 *   @title SafeMath
 *   @dev Math operations with safety checks that throw on error
 */

library SafeMath {

  function mul(uint a, uint b) internal constant returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal constant returns(uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal constant returns(uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal constant returns(uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 *   @title ERC20
 *   @dev Standart ERC20 token interface
 */

contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

} 

/**
 *   @title BondICO contract  - takes funds from users and issues tokens
 */
contract BondICO {
    // BFP - Datarius token contract
    using SafeMath for uint;
    BondToken public BFP = new BondToken(this);

    // Token price parameters
    // These parametes can be changed only by manager of contract
    uint public tokensPerDollar = 10;
    uint public rateEth = 1176; // Rate USD per ETH
    uint public tokenPrice = tokensPerDollar * rateEth; // DTRC per ETH

    //Crowdsale parameters 
    uint constant preSaleHardCap = 29000000 * 1e18;
    uint constant publicSaleHardCap = 347500000 * 1e18;
    uint constant bountyPart = 1; // 1% of TotalSupply for BountyFund
    uint constant advisorsPart = 3; // 3% of TotalSupply for AdvisorsFund
    uint constant teamPart = 207; // 20,7% of TotalSupply for TeamFund
    uint constant publicIcoPart = 753; // 75,3% of TotalSupply for publicICO
    uint public preSaleSold = 0;
    uint public publicSaleSold = 0;
    uint startTime = 0;
    // Output ethereum addresses
    address public Company;
    address public BountyFund;
    address public AdvisorsFund;
    address public TeamFund;
    address public Manager; // Manager controls contract
    address public ReserveManager; // // Manager controls contract
    address public Controller_Address1; // First address that is used to buy tokens for other cryptos
    address public Controller_Address2; // Second address that is used to buy tokens for other cryptos
    address public Controller_Address3; // Third address that is used to buy tokens for other cryptos
    address public Oracle; // Oracle address

    // Possible ICO statuses
    enum StatusICO {
        Created,
        PreIcoStarted,
        PreIcoPaused,
        PreIcoFinished,
        IcoStarted,
        IcoPaused,
        IcoFinished
    }
    StatusICO statusICO = StatusICO.Created;
    
    // Events Log
    event LogStartPreICO();
    event LogPausePreICO();
    event LogFinishPreICO();
    event LogStartICO();
    event LogPauseICO();
    event LogFinishICO();
    event LogBuyForInvestor(address investor, uint bfpValue, string txHash);

    // Modifiers
    // Allows execution by the managers only
    modifier managersOnly { 
        require(
            (msg.sender == Manager) ||
            (msg.sender == ReserveManager)
        );
        _; 
     }
    // Allows execution by the oracle only
    modifier oracleOnly { 
        require(msg.sender == Oracle);
        _; 
     }
    // Allows execution by the one of controllers only
    modifier controllersOnly {
        require(
            (msg.sender == Controller_Address1)||
            (msg.sender == Controller_Address2)||
            (msg.sender == Controller_Address3)
        );
        _;
    }

   /**
    *   @dev Contract constructor function
    */
    function DatariusICO(
        address _Company,
        address _BountyFund,
        address _AdvisorsFund,
        address _TeamFund,
        address _Manager,
        address _ReserveManager,
        address _Controller_Address1,
        address _Controller_Address2,
        address _Controller_Address3,
        address _Oracle
        ) public {
        Company = _Company;
        BountyFund = _BountyFund;
        AdvisorsFund = _AdvisorsFund;
        TeamFund = _TeamFund;
        Manager = _Manager;
        ReserveManager = _ReserveManager;
        Controller_Address1 = _Controller_Address1;
        Controller_Address2 = _Controller_Address2;
        Controller_Address3 = _Controller_Address3;
        Oracle = _Oracle;
    }

   /**
    *   @dev Function to set rate of ETH and update token price
    *   @param _rateEth       current ETH rate
    */
    function setRate(uint _rateEth) external oracleOnly {
        rateEth = _rateEth;
        tokenPrice = tokensPerDollar.mul(rateEth);
    }

   /**
    *   @dev Function to start Pre-ICO
    *   Sets ICO status to PreIcoStarted
    */
    function startPreIco() external managerOnly {
        require(statusICO == StatusICO.Created || statusICO == StatusICO.PreIcoPaused);
        statusICO = StatusICO.PreIcoStarted;
        LogStartPreICO();
    }

   /**
    *   @dev Function to pause Pre-ICO
    *   Sets ICO status to PreIcoPaused
    */
    function pausePreIco() external managerOnly {
       require(statusICO == StatusICO.PreIcoStarted);
       statusICO = StatusICO.PreIcoPaused;
       LogPausePreICO();
    }


   /**
    *   @dev Function to finish Pre-ICO
    *   Sets ICO status to PreIcoFinished
    */
    function finishPreIco() external managerOnly {
        require(statusICO == StatusICO.PreIcoStarted || statusICO == StatusICO.PreIcoPaused);
        statusICO = StatusICO.PreIcoFinished;
        LogFinishPreICO();
   
   /**
    *   @dev Function to start ICO
    *   Sets ICO status to Started
    */
    function startIco() external managersOnly {
        require(statusICO == StatusICO.PreIcoFinished || statusICO == StatusICO.IcoPaused);
        statusICO = statusICO.IcoStarted;
        LogStartICO();
    }

   /**
    *   @dev Function to pause ICO
    *   Sets ICO status to Paused
    */
    function pauseIco() external managersOnly {
       require(statusICO == StatusICO.IcoStarted);
       statusICO = StatusICO.IcoPaused;
       LogPauseICO();
    }

   /**
    *   @dev Function to finish ICO
    *   Emits tokens for bounty company, advisors and team
    */
    function finishIco() external managersOnly {
        require(statusICO == StatusICO.IcoStarted || statusICO == StatusICO.IcoPaused);
        uint alreadyMinted = BFP.totalSupply();
        uint totalAmount = alreadyMinted.mul(1000).div(publicIcoPart);
        BFP.mintTokens(BountyFund, bountyPart.mul(totalAmount).div(100));
        BFP.mintTokens(AdvisorsFund, advisorsPart.mul(totalAmount).div(100));
        BFP.mintTokens(TeamFund, teamPart.mul(totalAmount).div(1000));
        statusICO = StatusICO.Finished;
        LogFinishICO();
    }

   /**
    *   @dev Fallback function calls buy(address _investor, uint _bfpValue) function to issue tokens
    *        when investor sends ETH to address of ICO contract
    */
    function() external payable {
        buy(msg.sender, msg.value.mul(tokenPrice));
    }

   /**
    *   @dev Function to issues tokens for investors who made purchases in other cryptocurrencies
    *   @param _investor     address the tokens will be issued to
    *   @param _txHash       transaction hash of investor's payment
    *   @param _bfpValue     number of BFP tokens
    */

    function buyForInvestor(
        address _investor, 
        uint _bfpValue, 
        string _txHash
    ) 
        external 
        controllersOnly {
        buy(_investor, _bfpValue);
        LogBuyForInvestor(_investor, total, _txHash);
    }

   /**
    *   @dev Function to issue tokens for investors who paid in ether
    *   @param _investor     address which the tokens will be issued tokens
    *   @param _bfpValue     number of BFP tokens
    */
    function buy(address _investor, uint _bfpValue) internal {
        require(statusICO == StatusICO.IcoStarted || statusICO == StatusICO.PreIcoStarted);
        require(soldAmount + _DTRCValue <= hardCap);
        uint bonus = getBonus(_bfpValue);
        uint total = _DTRCValue.add(bonus);
        if (statusICO == StatusICO.PreIcoStarted) {
            require(preSaleSold + total <= preSaleHardCap);
            preSaleSold.add(total);
        } else {
            require(publicSaleSold + total <= publicSaleHardCap);
            publicSaleSold.add(total);            
        } 
        BFP.mintTokens(_investor, total);
    }



   /**
    *   @dev Calculates bonus 
    *   @param _value        amount of tokens
    *   @return              bonus value
    */
    function getBonus(uint _value) public constant returns (uint) {
        uint bonus = 0;
        if (statusICO == StatusICO.PreIcoStarted) {
            if(preSaleSold <= 6250000 * 1e18) {
                bonus = _value.mul(25).div(100);
                return bonus;
            }
            if(preSaleSold <= 12250000 * 1e18) {
                bonus = _value.mul(20).div(100);
                return bonus;
            }
            if(preSaleSold <= 18000000 * 1e18) {
                bonus = _value.mul(15).div(100);
                return bonus;
            }
            else {
                bonus = _value.mul(10).div(100);
                return bonus;
            }   
        } else {
           if(publicSaleSold <= 62500000 * 1e18) {
                bonus = _value.mul(25).div(100);
                return bonus;
            }
            if(publicSaleSold <= 122500000 * 1e18) {
                bonus = _value.mul(20).div(100);
                return bonus;
            }
            if(publicSaleSold <= 237500000 * 1e18) {
                bonus = _value.mul(15).div(100);
                return bonus;
            }
            else {
                bonus = _value.mul(10).div(100);
                return bonus;
            }
        }
    return bonus;
    }

  

   /**
    *   @dev Allows Company withdraw investments when ICO is over
    */
    function withdrawEther() external managersOnly {
        require(statusICO == StatusICO.Finished && soldAmount >= softCap);
        Company.transfer(this.balance);
    }

}

/**
 *   @title BondToken
 *   @dev Bond Film Platform token contract
 */
contract BondToken is ERC20 {
    using SafeMath for uint;
    string public name = "Bond Film Platform";
    string public symbol = "BFP";
    uint public decimals = 18;

    // Ico contract address
    address public ico;
    event Burn(address indexed from, uint value);
    
    // Tokens transfer ability status
    bool public tokensAreFrozen = true;

    // Allows execution by the owner only
    modifier icoOnly { 
        require(msg.sender == ico); 
        _; 
    }

   /**
    *   @dev Contract constructor function sets Ico address
    *   @param _ico          ico address
    */
    function BondToken(address _ico) public {
       ico = _ico;
    }

   /**
    *   @dev Function to mint tokens
    *   @param _holder       beneficiary address the tokens will be issued to
    *   @param _value        number of tokens to issue
    */
    function mintTokens(address _holder, uint _value) external icoOnly {
       require(_value > 0);
       balances[_holder] = balances[_holder].add(_value);
       totalSupply = totalSupply.add(_value);
       Transfer(0x0, _holder, _value);
    }


   /**
    *   @dev Function to enable token transfers
    */
    function defrost() external icoOnly {
       tokensAreFrozen = false;
    }


   /**
    *   @dev Burn Tokens
    *   @param _holder       token holder address which the tokens will be burnt
    *   @param _value        number of tokens to burn
    */
    function burnTokens(address _holder, uint _value) external icoOnly {
        require(balances[_holder] > 0);
        totalSupply = totalSupply.sub(_value);
        balances[_holder] = balances[_holder].sub(_value);
        Burn(_holder, _value);
    }

   /**
    *   @dev Get balance of tokens holder
    *   @param _holder        holder's address
    *   @return               balance of investor
    */
    function balanceOf(address _holder) constant returns (uint) {
         return balances[_holder];
    }

   /**
    *   @dev Send coins
    *   throws on any error rather then return a false flag to minimize
    *   user errors
    *   @param _to           target address
    *   @param _amount       transfer amount
    *
    *   @return true if the transfer was successful
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

   /**
    *   @dev An account/contract attempts to get the coins
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   @param _from         source address
    *   @param _to           target address
    *   @param _amount       transfer amount
    *
    *   @return true if the transfer was successful
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


   /**
    *   @dev Allows another account/contract to spend some tokens on its behalf
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   also, to minimize the risk of the approve/transferFrom attack vector
    *   approve has to be called twice in 2 separate transactions - once to
    *   change the allowance to 0 and secondly to change it to the new allowance
    *   value
    *
    *   @param _spender      approved address
    *   @param _amount       allowance amount
    *
    *   @return true if the approval was successful
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

   /**
    *   @dev Function to check the amount of tokens that an owner allowed to a spender.
    *
    *   @param _owner        the address which owns the funds
    *   @param _spender      the address which will spend the funds
    *
    *   @return              the amount of tokens still avaible for the spender
    */
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }
}