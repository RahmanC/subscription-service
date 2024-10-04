// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SubscriptionContract {
    address public owner;

    struct Service {
        string name;
        address provider;
        uint256 fee;
        uint256 duration; 
    }

    struct Subscriber {
        uint256 expiry; 
    }

    mapping(uint256 => Service) public services;
    mapping(address => mapping(uint256 => Subscriber)) public subscribers; // subscribers for each service
    uint256 public serviceCount = 0;

    event ServiceRegistered(uint256 serviceId, string name, address provider, uint256 fee, uint256 duration);
    event Subscribed(address subscriber, uint256 serviceId, uint256 expiry);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyProvider(uint256 serviceId) {
        require(services[serviceId].provider == msg.sender, "Only the provider of this service can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerService(string memory _name, uint256 _fee, uint256 _duration) public {
        require(_fee > 0, "Fee must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");

        serviceCount++;
        services[serviceCount] = Service({
            name: _name,
            provider: msg.sender,
            fee: _fee,
            duration: _duration
        });

        emit ServiceRegistered(serviceCount, _name, msg.sender, _fee, _duration);
    }

    function subscribe(uint256 _serviceId) public payable {
        Service memory service = services[_serviceId];
        require(msg.value >= service.fee, "Insufficient funds to subscribe");

        Subscriber storage subscriber = subscribers[msg.sender][_serviceId];
        if (subscriber.expiry > block.timestamp) {
            // If the user is already subscribed, extend their subscription
            subscriber.expiry += service.duration;
        } else {
            // Otherwise, start a new subscription
            subscriber.expiry = block.timestamp + service.duration;
        }

        // Transfer payment to the provider
        payable(service.provider).transfer(service.fee);

        emit Subscribed(msg.sender, _serviceId, subscriber.expiry);
    }

    function checkSubscription(address _subscriber, uint256 _serviceId) public view returns (bool) {
        return subscribers[_subscriber][_serviceId].expiry > block.timestamp;
    }

    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
