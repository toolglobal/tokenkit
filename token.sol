pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    modifier canTransfer (address _from, address _to, uint256 amount) {
        require((_from != address(0)) && (_to != address(0)));
        require(_from != _to);
        require(amount > 0);
        _;
    }

    function _sendAmount(address _from, address _to, uint _value) internal {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        balances[_from] = balances[_from].sub(_value);
        _sendAmount(_from,_to,_value);

    }

    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) canTransfer(msg.sender, _to, _value) returns (bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}

contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) canTransfer(_from,_to,_value) returns (bool) {
        uint _allowance = allowed[_from][msg.sender];

        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }

        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {

        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused external {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused external {
    paused = false;
    emit Unpause();
  }
}

contract BlackList is Ownable, BasicToken {

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;

    function addBlackList (address _evilUser) external onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) external onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) external onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply = _totalSupply.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

contract UpgradedStandardToken is StandardToken{
    function transferByLegacy(address from, address to, uint value) public returns (bool);
    function transferFromByLegacy(address sender, address from, address spender, uint value) public returns (bool);
    function approveByLegacy(address from, address spender, uint value) public returns (bool);
}

contract BatchTransferToken is StandardToken {
    function _tryCalcTotalAmount (address[] memory receivers, uint256 amount) internal pure returns (uint256) {
        require(amount > 0);

        uint receiveLength = receivers.length;
        uint receiverCount = 0;
        uint i;
        address r;
        for (i = 0; i < receiveLength; i ++) {
            r = receivers[i];
            if (r == address(0)) continue;
            receiverCount ++;
        }
        require(receiverCount > 0);

        uint256 totalAmount = amount.mul(uint256(receiverCount));
        return totalAmount;
    }

    function _tryCalcTotalAmount2 (address[] memory receivers, uint256[] memory amounts) internal pure returns (uint256) {
        uint receiveLength = receivers.length;
        require(receiveLength == amounts.length);

        uint256 totalAmount = 0;
        uint i;
        address r;
        for (i = 0; i < receiveLength; i ++) {
            r = receivers[i];
            if (r == address(0)) continue;
            if (amounts[i] == 0) continue;
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(totalAmount > 0);
        return totalAmount;
    }

    function _batchSend (address[] memory receivers, uint256 amount) internal {
        require(amount > 0);
        uint receiveLength = receivers.length;
        uint i;
        address r;
        for (i = 0; i < receiveLength; i++) {
            r = receivers[i];
            if (r == address(0)) continue;

            _sendAmount(msg.sender, r, amount);
        }
    }

    function _batchSend2 (address[] memory receivers, uint256[] memory amounts) internal {
        uint receiveLength = receivers.length;
        require(receiveLength == amounts.length);
        uint i;
        address r;
        uint256 amount;
        for (i = 0; i < receiveLength; i++) {
            r = receivers[i];
            if (r == address(0)) continue;
            amount = amounts[i];
            if (amount == 0) continue;

            _sendAmount(msg.sender, r, amount);
        }
    }

    function _trySubAllowance(address _spender, address _owner, uint256 _value) internal {
        if (_spender != _owner) {
            uint _allowance = allowed[_owner][_spender];

            if (_allowance < MAX_UINT) {
                require(_value <= _allowance);
                allowed[_owner][_spender] = _allowance.sub(_value);
            }
        }
    }
}

contract XYZTokenContract is Pausable, StandardToken, BlackList, BatchTransferToken {

    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    address public upgradedAddress = address(0);
    bool public deprecated = false;

    constructor(uint _initialSupply, string _name, string _symbol, uint8 _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    function transfer(address _to, uint _value) public whenNotPaused canTransfer(msg.sender,_to,_value) returns (bool){
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused canTransfer(_from,_to,_value) returns (bool){
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function balanceOf(address who) public view returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

	function deprecate(address _upgradedAddress) external onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function totalSupply() public view returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    function issue(uint amount) external onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);

        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }

    function redeem(uint amount) external onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) external onlyOwner {
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        uint d = decimals;
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**d);

        emit Params(basisPointsRate, maximumFee);
    }

    function batchTransfer (address[] receivers, uint256 amount) external {
        require(!isBlackListed[msg.sender]);

        uint256 totalAmount = _tryCalcTotalAmount(receivers,amount);
        require(totalAmount <= balances[msg.sender]);

        balances[msg.sender] =  balances[msg.sender].sub(totalAmount);
        _batchSend(receivers,amount);
    }

    function batchTransfers (address[] receivers, uint256[] amounts) external {
        require(!isBlackListed[msg.sender]);

        uint256 totalAmount = _tryCalcTotalAmount2(receivers,amounts);
        require(totalAmount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        _batchSend2(receivers,amounts);
    }

    function batchTransferFrom (address from, address[] receivers, uint256 amount) external {
        require(!isBlackListed[msg.sender]);
        require(from != address(0));

        uint256 totalAmount = _tryCalcTotalAmount(receivers,amount);
        require(totalAmount <= balances[from]);

        _trySubAllowance(msg.sender, from, totalAmount);

        balances[from] =  balances[from].sub(totalAmount);
        _batchSend(receivers,amount);
    }

    function batchTransferFroms (address from, address[] receivers, uint256[] amounts) external {
        require(!isBlackListed[msg.sender]);
        require(from != address(0));

        uint256 totalAmount = _tryCalcTotalAmount2(receivers,amounts);
        require(totalAmount <= balances[from]);

        _trySubAllowance(msg.sender, from, totalAmount);

        balances[from] =  balances[from].sub(totalAmount);
        _batchSend2(receivers,amounts);
    }

    event Issue(uint amount);

    event Redeem(uint amount);

    event Deprecate(address newAddress);

    event Params(uint feeBasisPoints, uint maxFee);
}
