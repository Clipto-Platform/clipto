// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./beacon/CloneableBeaconProxy.sol";
import "./interfaces/ICliptoToken.sol";
import "./CliptoExchangeStorage.sol";

contract CliptoExchange is CliptoExchangeStorage, Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 private _feeNumer;
    uint256 private _feeDenom;

    modifier onlyOwner() {
        require(owner == msg.sender, "not the owner");
        _;
    }

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event CreatorRegistered(address indexed creator, address indexed nft, string jsondata);
    event CreatorUpdated(address indexed creator, string jsondata);
    event NewRequest(address indexed creator, uint256 requestId, string jsondata);
    event DeliveredRequest(address indexed creator, uint256 requestId, uint256 nftTokenId);
    event RefundedRequest(address indexed creator, uint256 requestId);
    event RejectRequest(address indexed creator, uint256 requestId);
    event MigrationCreator(address[] creators);

    function initialize(address _owner, address _beacon) public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();

        beacon = _beacon;
        owner = _owner;
        _feeDenom = 1;
    }

    function getRequest(address _creator, uint256 _requestId) external view returns (Request memory) {
        return requests[_creator][_requestId];
    }

    function getCreator(address _creator) external view returns (address) {
        return creators[_creator];
    }

    function getFeeRate() external view returns (uint256, uint256) {
        return (_feeNumer, _feeDenom);
    }

    function setFeeRate(uint256 feeNumer_, uint256 feeDenom_) external onlyOwner {
        require(feeDenom_ != 0, "error: denom should be non zero");
        require(feeNumer_ <= feeDenom_, "error: denom should be smaller than numer");

        _feeNumer = feeNumer_;
        _feeDenom = feeDenom_;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setCliptoMinter(address _cliptoToken, address _minter) external onlyOwner {
        ICliptoToken(_cliptoToken).setMinter(_minter);
    }

    function registerCreator(string calldata _creatorName, string calldata _jsondata) external whenNotPaused {
        require(!_existsCreator(msg.sender), "error: creator already registered");
        _registerCreator(msg.sender, _creatorName, _jsondata);
    }

    function updateCreator(string calldata _jsondata) external whenNotPaused {
        require(_existsCreator(msg.sender), "error: creator is not yet registered");
        emit CreatorUpdated(msg.sender, _jsondata);
    }

    function newRequest(
        address _creator,
        address _nftReceiver,
        address _erc20,
        uint256 _amount,
        string calldata _jsonData
    ) external whenNotPaused {
        _validateRequest(_creator, _amount);
        _checkAllowance(_erc20, msg.sender, _amount);
        _pay(msg.sender, address(this), _erc20, _amount);
        _newRequest(_creator, _nftReceiver, _erc20, _amount, _jsonData);
    }

    function nativeNewRequest(
        address _creator,
        address _nftReceiver,
        string calldata _jsonData
    ) external payable whenNotPaused {
        _validateRequest(_creator, msg.value);
        _newRequest(_creator, _nftReceiver, address(0), msg.value, _jsonData);
    }

    function deliverRequest(uint256 _requestId, string calldata _tokenURI) external nonReentrant whenNotPaused {
        Request storage request = requests[msg.sender][_requestId];
        require(!request.fulfilled, "error: request already fulfilled/refunded");

        uint256 feeAmount = (request.amount * _feeNumer) / _feeDenom;
        _transferPayment(owner, request.erc20, feeAmount);

        uint256 paymentAmount = request.amount - feeAmount;
        _transferPayment(msg.sender, request.erc20, paymentAmount);

        address nft = creators[msg.sender];
        uint256 nftTokenId = ICliptoToken(nft).totalSupply();
        ICliptoToken(nft).safeMint(request.nftReceiver, _tokenURI);

        request.fulfilled = true;
        emit DeliveredRequest(msg.sender, _requestId, nftTokenId + 1);
    }

    function refundRequest(address _creator, uint256 _requestId) external nonReentrant whenNotPaused {
        Request storage request = requests[_creator][_requestId];
        require(request.requester == msg.sender, "error: only requester can make a refund");
        require(!request.fulfilled, "error: request already fulfilled/refunded");

        _transferPayment(msg.sender, request.erc20, request.amount);
        request.fulfilled = true;

        emit RefundedRequest(_creator, _requestId);
    }

    function rejectRequest(uint256 _requestId) external whenNotPaused {
        Request storage request = requests[msg.sender][_requestId];
        require(!request.fulfilled, "error: request already fulfilled/refunded");

        request.fulfilled = true;
        emit RejectRequest(msg.sender, _requestId);
    }

    function migrateCreator(address[] calldata _creatorAddress, string[] calldata _creatorNames) external onlyOwner {
        require(_creatorAddress.length > 0, "error: empty creator address");

        uint256 i;
        for (i = 0; i < _creatorAddress.length; i++) {
            address nft = _deployCliptoFor(_creatorAddress[i], _creatorNames[i]);
            creators[_creatorAddress[i]] = nft;
        }

        emit MigrationCreator(_creatorAddress);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _transferPayment(
        address _to,
        address _erc20,
        uint256 _amount
    ) internal {
        if (_erc20 == address(0)) _pay(_to, _amount);
        else _pay(address(this), _to, _erc20, _amount);
    }

    function _registerCreator(
        address _creator,
        string calldata _creatorName,
        string calldata _jsondata
    ) internal {
        address nft = _deployCliptoFor(msg.sender, _creatorName);
        creators[_creator] = nft;

        emit CreatorRegistered(_creator, nft, _jsondata);
    }

    function _validateRequest(address _creator, uint256 _amount) internal view {
        require(_existsCreator(_creator), "error: creator does not exists");
        require(_amount > 0, "amount should be greater than 0");
    }

    function _newRequest(
        address _creator,
        address _nftReceiver,
        address _erc20,
        uint256 _amount,
        string calldata _jsondata
    ) internal {
        requests[_creator].push(Request(msg.sender, _nftReceiver, _erc20, _amount, false));
        emit NewRequest(_creator, requests[_creator].length - 1, _jsondata);
    }

    function _existsCreator(address _creator) internal view returns (bool) {
        return creators[_creator] != address(0);
    }

    function _deployCliptoFor(address _creator, string calldata _creatorName) internal returns (address) {
        CloneableBeaconProxy proxy = new CloneableBeaconProxy();
        address nftAddress = address(proxy);

        require(nftAddress != address(0), "error: beacon proxy deploy failed");
        proxy.__ClonableBeacon_init(beacon);
        ICliptoToken(nftAddress).initialize(_creator, address(this), _creatorName);
        return nftAddress;
    }

    function _checkAllowance(
        address _erc20,
        address _from,
        uint256 _amount
    ) internal view {
        uint256 allowance = IERC20(_erc20).allowance(_from, address(this));
        require(allowance >= _amount, "error: allowance is either not given or is insufficient");
    }

    function _pay(
        address _from,
        address _to,
        address _erc20,
        uint256 _amount
    ) internal {
        bool sent;
        if (_from == address(this)) {
            sent = IERC20(_erc20).transfer(_to, _amount);
        } else {
            sent = IERC20(_erc20).transferFrom(_from, _to, _amount);
        }
        require(sent, "error: payment transfer failed");
    }

    function _pay(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "error: payment transfer failed");
    }
}
