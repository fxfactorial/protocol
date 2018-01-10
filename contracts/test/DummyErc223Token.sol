pragma solidity 0.4.18;


/// @dev ERC223 contract interface
contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);

    function name() constant returns (string _name);
    function symbol() constant returns (string _symbol);
    function decimals() constant returns (uint8 _decimals);
    function totalSupply() constant returns (uint256 _supply);
    function transfer(address to, uint value) returns (bool ok);
    function transfer(
        address to,
        uint value,
        bytes data) returns (bool ok);

    function transfer(
        address to,
        uint value,
        bytes data,
        string customFallback) returns (bool ok);

    event Transfer(
        address indexed  from,
        address indexed  to,
        uint             value,
        bytes   indexed  data
    );
}


/// @dev Contract that is working with ERC223 tokens
contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);

        /* tkn variable is analogue of msg variable of Ether transaction
         *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
         *  tkn.value the number of tokens that were sent   (analogue of msg.value)
         *  tkn.data is data of token transaction   (analogue of msg.data)
         *  tkn.sig is 4 bytes signature of function
         *  if data of token transaction is a function execution
         */
    }
}


contract SafeMath {
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y)
            revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y)
            revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0)
            return 0;
        if (x > MAX_UINT256 / y)
            revert();
        return x * y;
    }
}


contract DummyERC223Token is ERC223, SafeMath {
    mapping(address => uint) balances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address public owner;

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev constructor
    function DummyERC223Token(
        string _name,
        string _symbol,
        uint8  _decimals,
        uint   _totalSupply
        )
        public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        owner = msg.sender;
        balances[msg.sender] = _totalSupply;
    }

    /// @dev set balance for any address. used for unit test.
    function setBalance(
        address _target,
        uint _value
        )
        onlyOwner
        public
    {
        uint currBalance = balanceOf(_target);
        if (_value < currBalance) {
            totalSupply = totalSupply - (currBalance - _value);
        } else {
            totalSupply = totalSupply + (_value - currBalance);
        }
        balances[_target] = _value;
    }

    /// Function that is called when a user or another contract wants to transfer funds .
    function transfer(
        address _to,
        uint _value,
        bytes _data,
        string _customFallback) returns (bool success)
    {
        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value)
                throw;
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            assert(
                _to.call.value(0)(
                    bytes4(sha3(_customFallback)),
                    msg.sender,
                    _value,
                    _data
                )
            );

            Transfer(
                msg.sender,
                _to,
                _value,
                _data
            );

            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    /// Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    /// Standard function transfer similar to ERC20 transfer with no _data .
    /// Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) returns (bool success) {
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    /// assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool) {
        uint length;
        assembly
        {
            // retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }

        return length > 0;
    }

    /// function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value)
            throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(
            msg.sender,
            _to,
            _value,
            _data
        );

        return true;
    }

    /// function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value)
            throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(
            msg.sender,
            _to,
            _value,
            _data
        );

        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}
