pragma solidity 0.5.3;

// ----------------------------------------------------------------------------
// 'DECA' DEcentralized CArbon tokens - ITDE (initial token distribution event)
//
// Deployed to : 0xD9497a4ee4D9E6E73EC1126D2f7827DEA8A51154
// Network     : Ropsten
// Symbol      : DECA
// Name        : Decentralized Carbon tokens 
// Total supply: Gazillion
// Decimals    : 18
//
// Enjoy.
//
// (c) by Moritz Neto & Daniel Bar with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
// fork and modifications to fix DECA's ICO needs by p1r0 <p1r0@neetsec.com> and kaicudon <kaicudon@neetsec.com>
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
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
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    uint public startDate;
    uint public preICOEnds;
    uint public bonus1Ends;
    uint public bonus2Ends;
    uint public endDate;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor () public {
        symbol = "DECA";
        name = "DEcentralized CArbon tokens";
        decimals = 18;
        //for testing change weeks for days...
        preICOEnds = now + 1 days;
        bonus1Ends = now + 3 days;
        bonus2Ends = now + 6 days;
        endDate = now + 11 days;

    }

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Address cannot be zero");
        _;
    }

    modifier onlySufficientBalance(address from, uint256 tokens) {
        require(tokens <= balances[from], "Insufficient balance");
        _;
    }
    
    modifier onlySufficientAllowance(address owner, address spender, uint256 value) {
        require(value <= allowed[owner][spender], "Insufficient allowance");
        _;
    }

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
    function transfer(address to, uint tokens) public onlySufficientBalance(msg.sender, tokens) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Increases the amount of tokens that an owner allowed to a spender.
    //
    // approve should be called when _allowance[spender] == 0. To increment
    // allowed value is better to use this function to avoid 2 calls (and wait until
    // the first transaction is mined)
    // 'spender' The address which will spend the funds.
    // 'addedValue' The amount of tokens to increase the allowance by.
    // ------------------------------------------------------------------------
    function increaseAllowance(address spender, uint256 addedValue) public 
    onlyValidAddress(spender) 
    returns (bool){
        allowed[msg.sender][spender] = safeAdd(allowed[msg.sender][spender], addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // ------------------------------------------------------------------------
    // Decreases the amount of tokens that an owner allowed to a spender.
    //
    // approve should be called when _allowance[spender] == 0. To decrement
    // allowed value is better to use this function to avoid 2 calls (and wait until
    // the first transaction is mined)
    // 'spender' The address which will spend the funds.
    // 'param' subtractedValue The amount of tokens to decrease the allowance by.
    // ------------------------------------------------------------------------
    function decreaseAllowance(address spender, uint256 subtractedValue) public 
    onlyValidAddress(spender) 
    onlySufficientAllowance(msg.sender, spender, subtractedValue)
    returns (bool){
        allowed[msg.sender][spender] = safeSub(allowed[msg.sender][spender], subtractedValue);
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
    function transferFrom(address from, address to, uint tokens) public 
    onlyValidAddress(to)
    onlySufficientBalance(from, tokens)
    onlySufficientAllowance(from, msg.sender, tokens)
    returns (bool success) {
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
    // 1,000 DECA Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () external payable {
        require(now >= startDate && now <= endDate);
        uint tokens;
        uint toOwner;
        uint toSender;
        uint percentage;
        
        percentage = 2; // percentage that goes to the owner

        if (now <= preICOEnds) {
            tokens = msg.value * 2000;
        } else if (now > preICOEnds && now <= bonus1Ends ) {  
            tokens = msg.value * 1500;
        } else if (now > bonus1Ends && now <= bonus2Ends) {  
            tokens = msg.value * 1250;
        } else {
            tokens = msg.value * 1000;
        }
        toOwner = safeDiv(tokens, percentage); // percentage assigned to the contract owner (DAO)
        toSender = tokens; // tokens goes to sender
        balances[msg.sender] = safeAdd(balances[msg.sender], toSender);
        balances[owner] = safeAdd(balances[owner], toOwner);
        totalSupply = safeAdd(totalSupply, safeAdd(tokens,safeDiv(tokens, percentage)));
        emit Transfer(address(0), msg.sender, toSender);
        emit Transfer(address(0), owner, toOwner);
        address(owner).transfer(msg.value);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
