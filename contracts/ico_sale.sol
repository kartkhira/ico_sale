
pragma solidity ^0.8.7;

import "hardhat/console.sol";
// Chainlink oracle data feed
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ico_sale {

AggregatorV3Interface internal priceFeed;

address admin;
uint phase1softcap;
uint phase2Softcap;
uint phase1Hardcap;
uint phase2Hardcap;
uint phase1TokenPrice;
uint phase2TokenPrice;
uint maxInvestment;
uint256 icoStartTime;

int TotalPhase1Supply;
int TotalPhase2Supply;
bool ico_started = false;

// Use constructor to identify admin and get the variables passed
constructor() payable {
    admin = msg.sender;
    priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
}

struct FundsRaised
{
  uint phase1Fund;
  uint phase2Fund;
}

// Requesters list. To be used to deliver tokens on ICO ending
struct requestees{
  address[] requesters;
  uint count;
}
requestees Requestees;
FundsRaised fundsraised;

   /**
     * Returns the latest price
     */
     // TO-DO : Data feed not working correctly on remix
function getLatestPrice() public view returns (int) {
    (
    /*uint80 roundID*/,
      int price,
        /*uint startedAt*/,
       /*uint timeStamp*/,
       /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();

        return price;
}

modifier isAdmin(address _addr){
    require(msg.sender == admin,"This api can only be called by admin");
    _;
}
// Create as a whitelist for easy loopup
mapping (address => bool) whitelist;
mapping (address =>uint) tokenbal;
mapping(address => uint) tokenReleased;

// Function to add in whitelis
function addInwhitelist(address _addr ) public isAdmin(msg.sender){

    whitelist[_addr] = true;

}
// Modifier for req control
modifier isInwhitelist(address _addr){
    require(whitelist[_addr] == true,"You are not whitelisted");
    _;
}

// Initialize params for ICO before ICO has started
// First API to be called
// Parametes can be passed to provide plug and play ICO
function intializeParams(uint softCap1, uint softCap2, 
                         uint hardCap1, uint hardCap2,
                         uint tokenPrice1, uint tokenPrice2,
                         uint max_invest
                         ) 
                         public isAdmin(msg.sender)
{
    // Set the contract storage variables
    require(ico_started == false, "ICO already started, can't update");
    if(!ico_started)
    {
        phase1softcap = softCap1 ;
        phase2Softcap = softCap2;
        phase1Hardcap = hardCap1;
        phase2Hardcap = hardCap2;
        phase1TokenPrice = tokenPrice1;
        phase2TokenPrice = tokenPrice2;
        maxInvestment = max_invest;

        TotalPhase1Supply = int(phase1Hardcap/phase1TokenPrice);
        TotalPhase2Supply = int(phase2Hardcap/phase2TokenPrice);

    }
}

// Start the ICO
function startICO() public isAdmin(msg.sender){

    ico_started = true;
    icoStartTime = block.timestamp;
    Requestees.count =0;
}

// Function to get the phase.
// Phase 2 starts 1 day after phase 1 ends automatically
function getPhase() public view returns(string memory){

    if( block.timestamp < icoStartTime + 86400 )
    {
        return 'Phase1';
    }
    else
    {
        return 'Phase2';
    }
}

// Function to compare strings
function compareStrings(string memory a, string memory b) public pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
}

// function to get token price based on phase
function getTokenPrice() public view returns(uint)
{
    if(compareStrings(getPhase(),'Phase1'))
    {
        return phase1TokenPrice;
    }
    else if(compareStrings(getPhase(),'Phase2'))
    {
        return phase2TokenPrice;
    }
    else
    {
        // implying ICO has not started
        return 0;
    }
}

// This function can only be called if whitelisting is established
function checkCap(uint _numtoken) internal view
{
    require(getTokenPrice()*(tokenbal[msg.sender] + _numtoken) < 100,"Too Large investment: Total Investment value is capped at 100USD");
}

// update the internal token supply 
function updateTokenSupply(uint num_tokens) private {
    int _num_tokens = int(num_tokens);
      if(compareStrings(getPhase(),'Phase1'))
    {
        require(TotalPhase1Supply - _num_tokens >0," Max supply cap reached fo this phase");
        TotalPhase1Supply -= _num_tokens;
    }
    else if(compareStrings(getPhase(),'Phase2'))
    {
       require(TotalPhase2Supply - _num_tokens >0," Max supply cap reached fo this phase");
       TotalPhase2Supply -= _num_tokens;
    }
    else
    {
        require(ico_started == true, "ICO has not started, can't update supply");
    }
}

// Update the variables to track funds raised
function updateFundsRaised(uint num_tokens) private 
{
      if(compareStrings(getPhase(),'Phase1'))
    {
        fundsraised.phase1Fund +=  (phase1TokenPrice)*(num_tokens);

    }
    else if(compareStrings(getPhase(),'Phase2'))
    {
        fundsraised.phase2Fund += (phase2TokenPrice)*(num_tokens);
    }
    else
    {
        require(ico_started == true, "ICO has not started, can't update supply");
    }
}
// Add in the requesters data struct on getting req from whitelisted candidate
function addRequester(address _sender_address) private {

  Requestees.requesters.push(_sender_address);
  Requestees.count += 1;

}

// This api will be called by the whitelisted candiate to req for tokens
function reqTokens() public payable isInwhitelist(msg.sender)
{
    uint amount = msg.value;
    require(ico_started == true, "ICO has not started, can't accept requests");
    // get latest price is integer with 
    uint256 ethInUSD = amount*uint(getLatestPrice())/(10**18);

    require(ethInUSD < maxInvestment,"Too Large investment: Investment value is capped at 100USD");

    uint num_tokens = ethInUSD/getTokenPrice();
    require(getTokenPrice()*(tokenbal[msg.sender] + num_tokens) < 100,"Too Large investment: Total Investment value is capped at 100USD");
    
    updateTokenSupply(num_tokens);
    tokenbal[msg.sender] = tokenbal[msg.sender] + num_tokens;
    updateFundsRaised(num_tokens);

    addRequester(msg.sender);
} 

// Get total money raised
function getFundsRaised() public view isAdmin(msg.sender) returns(uint, uint, uint)
{
  return (fundsraised.phase1Fund, fundsraised.phase2Fund, fundsraised.phase1Fund + fundsraised.phase2Fund );
}

// Stop the ICO and release the tokens
function stopAndRelease() public isAdmin(msg.sender)
{
    // This will iterate through all the requesters and release the tokens
  for(uint i =0; i< Requestees.count;i++ ){
      tokenReleased[Requestees.requesters[i]] = tokenbal[Requestees.requesters[i]];
  }

}

// Any candidate can ask for the token balance released on them
function getTokenBal() public view returns(uint){
  return tokenReleased[msg.sender];
}

// This function gets the current balance of the contract
function getContractBalance() public view returns(uint){

  return address(this).balance;

}

}

