pragma solidity 0.5.3;

// ----------------------------------------------------------------------------
// 'DECA' DEcentralized CArbon tokens - ITDE (initial token distribution event)
//
// Deployed to : ------
// Network     : Ropsten
// Symbol      : DECA
// Name        : Decentralized Carbon tokens 
// Total supply: Gazillion
// Decimals    : 18
//
// (c) by Moritz Neto & Daniel Bar with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
// fork and modifications to fix DECA's ICO needs by p1r0 <p1r0@neetsec.com>,
// Oscar <oscar@neetsec.com> and kaicudon <kaicudon@neetsec.com>
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function getTotalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function increaseApproval (address spender, uint tokens) public returns (bool success); 
    function decreaseApproval (address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
        
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;
    address payable public newOwner;
    string public CCDBAddress;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    // ----------------------------------------------------------------------------
    //Function that updates the orbitDB address at IPFS
    //This database will store the carbon credits gotten by the 20% DECAS that the contract owner recives
    // ----------------------------------------------------------------------------
    function updateCCDBAddress(string memory _CCDBAddress) public onlyOwner {
       CCDBAddress = _CCDBAddress;
    }
    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract DECAToken is ERC20Interface, Owned, SafeMath {
    string constant public symbol = "DECA";
    string constant public name = "DEcentralized CArbon tokens";
    uint8 constant public decimals = 18;
    uint public totalSupply;
    //for testing change weeks for hours...
    uint public preICOEnds = now + 1 hours;
    uint public bonus1Ends = now + 3 hours;
    uint public bonus2Ends = now + 6 hours;
    uint public endDate = now + 11 hours;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Total supply: Get the total token supply
    // ------------------------------------------------------------------------ 
    function getTotalSupply() public view returns (uint) {
        return totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        // approve should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'increaseApproval' and 'decreaseApproval'
        if (allowed[msg.sender][spender] == 0 || tokens == 0){
            emit Approval(msg.sender, spender, tokens);
            return true;
        }
        return false;
    }

    // ------------------------------------------------------------------------
    // approve should be called when allowed[spender] == 0. To increment
    // allowed value is better to use this function to avoid 2 calls (and wait until 
    // the first transaction is mined)
    // ------------------------------------------------------------------------
    function increaseApproval (address spender, uint tokens) public returns (bool success){
        allowed[msg.sender][spender] = safeAdd(allowed[msg.sender][spender], tokens);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval (address spender, uint tokens) public returns (bool success) {
        uint oldValue = allowed[msg.sender][spender];
        if (tokens > oldValue) {
            allowed[msg.sender][spender] = 0;
        } 
        else{
            allowed[msg.sender][spender] = safeSub(oldValue, tokens);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    // ------------------------------------------------------------------------
    // 100 DECA Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () external payable {
        require(now <= endDate);
        uint tokens;
        uint toOwner;
        uint toSender;
        uint divBy;
        // ------------------------------------------------------------------------
        // We want to have 20% of the DECA tokens market cap in order to exchange
        // them for carbon credits and have a better decentralization
        // NOTE: The Contract Owner must publish this usage in the orbitdb database
        // in order to prove that it's not holding using them with any other propose
        // (this can be also verified by the blockchain).
        // ------------------------------------------------------------------------ 
        divBy = 4; // 25% extra printed to be 20% of the marketcap, please see README.md

        if (now <= preICOEnds) {
            tokens = msg.value * 200;
        } else if (now > preICOEnds && now <= bonus1Ends ) {  
            tokens = msg.value * 150;
        } else if (now > bonus1Ends && now <= bonus2Ends) {  
            tokens = msg.value * 125;
        } else {
            tokens = msg.value * 100;
        }

        toOwner = safeDiv(tokens, divBy); //created 25% extra to the contract owner
        toSender = tokens; //tokens that goes to the sender
        balances[msg.sender] = safeAdd(balances[msg.sender], toSender);
        balances[owner] = safeAdd(balances[owner], toOwner);
        totalSupply = safeAdd(totalSupply, safeAdd(toSender,toOwner));
        emit Transfer(address(0), msg.sender, toSender);
        emit Transfer(address(0), owner, toOwner);
    }

    //Close down the ICO and claim the Ether.
    function getETH() public onlyOwner {
        require(now >= endDate );
        // transfer the ETH balance in the contract to the owner
        owner.transfer(address(this).balance); 
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
