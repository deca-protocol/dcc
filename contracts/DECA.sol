pragma solidity 0.5.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
// ----------------------------------------------------------------------------
// 'DECA' DEcentralized CArbon tokens - ITDE (initial token distribution event)
//
// Deployed to : ------
// Network     : Ropsten
// Symbol      : DECA
// Name        : DEcentralized CArbon tokens
// Total supply: Gazillion
// Decimals    : 18
// 
// Designed and wrote by D. Perez Negron <david@neetsec.com> A.K.A p1r0
// Test and Migrations to truffle by vitaliykuzmich
// ----------------------------------------------------------------------------
/**
 * @dev The reason using this instead of openzeppelin, because owner are not 'payable'
 */
contract Ownable is Context {
    address payable private _owner;
    using SafeMath for uint256;
    string public _CCDBAddress;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
    *Function that updates the official orbitDB address for carbon credits.
    *Can Only be updated by the current owner
    */
    function updateCCDBAddress(string memory newCCDBAddress) public onlyOwner {
       _CCDBAddress = newCCDBAddress;
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract DECA is ERC20, Ownable {
    using SafeMath for uint256;
    string constant public symbol = "DECA";
    string constant public name = "DEcentralized CArbon tokens";
    uint8 constant public decimals = 18;
    //for testing change weeks for hours...
    uint public preICOEnds = now + 1 weeks;
    uint public bonus1Ends = now + 3 weeks;
    uint public bonus2Ends = now + 6 weeks;
    uint public endDate = now + 11 weeks;
    bool private _pause = false;

    modifier notPaused() {
        require(!_pause, "crowdsale on pause");
        _;
    }
    function getPause() view public returns (bool){
        return _pause;
    }

    function setPause(bool p) external onlyOwner {
        _pause = p;
    }
    // ------------------------------------------------------------------------
    // 100 DECA Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function() notPaused external payable {
        require(now <= endDate);
        uint tokens;
        uint toOwner;
        uint toSender;
        uint divBy;

        divBy = 40;
        //2.5% extra printed to be 2% of the marketcap, please see README.md
        if (now <= preICOEnds) {
            tokens = msg.value * 300;
        } else if (now > preICOEnds && now <= bonus1Ends) {
            tokens = msg.value * 275;
        } else if (now > bonus1Ends && now <= bonus2Ends) {
            tokens = msg.value * 250;
        } else {
            tokens = msg.value * 225;
        }

        toOwner = tokens.div(divBy);
        //created 2.5% extra to the contract owner to approach 2% total marketcap
        toSender = tokens;
        //tokens that goes to the sender

        _mint(owner(), toOwner);
        _mint(msg.sender, toSender);
    }

    //Add weeks in case ICO gets not enough funds
    function appendWeeks(uint addWeeks ) public onlyOwner {
        require(now >= bonus2Ends && now < endDate);
        // Fix Integer Overflow / Underflow
        require(endDate < (endDate + (addWeeks * 1 weeks)));
        // add weeks to the endDate
        endDate += (addWeeks * 1 weeks);
    }
    
    //Close down the ICO and claim the Ether.
    function getETH() public onlyOwner {
        require(now >= endDate);
        // transfer the ETH balance in the contract to the owner
        owner().transfer(address(this).balance);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address payable tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(owner(), tokens);
    }
}
