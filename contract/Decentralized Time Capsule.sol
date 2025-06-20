// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Time Capsule
 * @dev A smart contract that allows users to store messages/data that can only be accessed after a specified time
 * @author Your Name
 */
contract Project {
    
    struct TimeCapsule {
        address owner;
        string message;
        uint256 unlockTime;
        bool isRevealed;
        bool exists;
    }
    
    mapping(uint256 => TimeCapsule) public timeCapsules;
    mapping(address => uint256[]) public userCapsules;
    
    uint256 private capsuleCounter;
    
    event CapsuleCreated(
        uint256 indexed capsuleId,
        address indexed owner,
        uint256 unlockTime
    );
    
    event CapsuleRevealed(
        uint256 indexed capsuleId,
        address indexed owner,
        string message
    );
    
    modifier onlyOwner(uint256 _capsuleId) {
        require(timeCapsules[_capsuleId].owner == msg.sender, "Not the owner of this capsule");
        _;
    }
    
    modifier capsuleExists(uint256 _capsuleId) {
        require(timeCapsules[_capsuleId].exists, "Capsule does not exist");
        _;
    }
    
    modifier canReveal(uint256 _capsuleId) {
        require(block.timestamp >= timeCapsules[_capsuleId].unlockTime, "Capsule is still locked");
        require(!timeCapsules[_capsuleId].isRevealed, "Capsule already revealed");
        _;
    }
    
    /**
     * @dev Creates a new time capsule with a message and unlock time
     * @param _message The message to store in the time capsule
     * @param _unlockTime The timestamp when the capsule can be opened
     * @return capsuleId The ID of the created capsule
     */
    function createCapsule(string memory _message, uint256 _unlockTime) 
        external 
        returns (uint256 capsuleId) 
    {
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        require(bytes(_message).length > 0, "Message cannot be empty");
        require(bytes(_message).length <= 1000, "Message too long (max 1000 characters)");
        
        capsuleId = capsuleCounter++;
        
        timeCapsules[capsuleId] = TimeCapsule({
            owner: msg.sender,
            message: _message,
            unlockTime: _unlockTime,
            isRevealed: false,
            exists: true
        });
        
        userCapsules[msg.sender].push(capsuleId);
        
        emit CapsuleCreated(capsuleId, msg.sender, _unlockTime);
        
        return capsuleId;
    }
    
    /**
     * @dev Reveals the message in a time capsule if the unlock time has passed
     * @param _capsuleId The ID of the capsule to reveal
     * @return message The revealed message
     */
    function revealCapsule(uint256 _capsuleId) 
        external 
        capsuleExists(_capsuleId)
        onlyOwner(_capsuleId)
        canReveal(_capsuleId)
        returns (string memory message) 
    {
        TimeCapsule storage capsule = timeCapsules[_capsuleId];
        capsule.isRevealed = true;
        
        emit CapsuleRevealed(_capsuleId, msg.sender, capsule.message);
        
        return capsule.message;
    }
    
    /**
     * @dev Gets information about a time capsule (without revealing the message if still locked)
     * @param _capsuleId The ID of the capsule
     * @return owner The owner of the capsule
     * @return unlockTime The unlock timestamp
     * @return isRevealed Whether the capsule has been revealed
     * @return canBeRevealed Whether the capsule can currently be revealed
     */
    function getCapsuleInfo(uint256 _capsuleId) 
        external 
        view 
        capsuleExists(_capsuleId)
        returns (
            address owner,
            uint256 unlockTime,
            bool isRevealed,
            bool canBeRevealed
        ) 
    {
        TimeCapsule storage capsule = timeCapsules[_capsuleId];
        
        return (
            capsule.owner,
            capsule.unlockTime,
            capsule.isRevealed,
            block.timestamp >= capsule.unlockTime
        );
    }
    
    /**
     * @dev Gets the list of capsule IDs owned by a user
     * @param _user The address of the user
     * @return An array of capsule IDs
     */
    function getUserCapsules(address _user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return userCapsules[_user];
    }
    
    /**
     * @dev Gets the total number of capsules created
     * @return The total number of capsules
     */
    function getTotalCapsules() external view returns (uint256) {
        return capsuleCounter;
    }
    
    /**
     * @dev Checks if a capsule can be revealed (time has passed and not already revealed)
     * @param _capsuleId The ID of the capsule
     * @return Whether the capsule can be revealed
     */
    function canRevealCapsule(uint256 _capsuleId) 
        external 
        view 
        capsuleExists(_capsuleId)
        returns (bool) 
    {
        TimeCapsule storage capsule = timeCapsules[_capsuleId];
        return block.timestamp >= capsule.unlockTime && !capsule.isRevealed;
    }
}
