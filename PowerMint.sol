// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract PowerMint is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    constructor(
        // uint256 _totalLimit,
        // uint256 _whitelistLimit,
        // uint256 _platformLimit
    ) ERC721(' PowerMInt', 'PWM') {
        baseURI = 'https://gateway.pinata.cloud/ipfs/';
        mintingStatus = true;
        cOwner = msg.sender;
        // if (_whitelistLimit + _platformLimit > totalLimit) {
        //     totalLimit = _totalLimit;
        //     whitelistLimitLeft = _whitelistLimit;
        //     totalwhitelistLimit = _whitelistLimit;
        //     platformLimitLeft = _platformLimit;
        //     totalPlatformLimit = _platformLimit;
        //     publicLimitLeft = totalLimit - (whitelistLimitLeft + platformLimitLeft);
        //     totalPublicLimit = totalLimit - (whitelistLimitLeft + platformLimitLeft);
        // } else {
        //     revert NotEqualToTotalLimit();
        // }
    }

    //Struct

    struct nftinfo {
        string Name;
        string Hash;
    }

    struct admininfo{
        string name;
        uint adminId;
    }

    struct adminsrecord{
        address addrs;
        string name;

    }

    struct mintinglimits{
        uint totalLimit;
        uint whitelistLimit;
        uint PlatformLimit;
        uint publicLimit;
        

    }

    // struct whitelist{
    //     address whitelistUser;

    // }

    // Variables
    uint public adminsCount;
    address public cOwner;
    uint256 public adminPrice = 0.01 ether;
    string public baseURI;
    // string public publicSales = 'Unactive';
    bool public mintingStatus;
    uint256 public totalLimit;
    // uint256 public whitelistLimitLeft;
    // uint256 public platformLimitLeft;
    // uint256 public publicLimitLeft;
    uint256 public userLimit = 5;
    uint256 private totalLimitCount;
    uint256 public totalwhitelistLimit;
    uint256 public totalPublicLimit;
    uint256 public totalPlatformLimit;
    // bool private mintingBool;
    bool private publicSaleBool;

    // Mappings
    mapping(address => admininfo) public adminDetails;
    mapping(uint => adminsrecord) public adminsRecord;
    mapping(address => bool) public isAdmin;
    mapping(uint => mintinglimits) public mintingLimits;
    mapping(uint256 => nftinfo) public nftData;
    mapping(address => bool) public isWhitelistedUser;
    mapping(uint256 => mapping(address => bool)) public checkWhitelistedUser;
    mapping(uint256 => address[]) private WhitelistedUser;
    mapping(uint256 => bool) public adminIdCheck;
    mapping(address => bool) public isWhitelistedAdmin;
    mapping(address => uint256) public userMintedStatus;

    // Events

    event WhitlistUserMinited(address calledby,address mintedto,uint tokenId,string name);
    event PulblicUserMinited(address calledby,address mintedto,uint tokenId,string name);
    event AdminMinited(address calledby,address mintedto,uint tokenId,string name);
    event AdminWhitelisted(address owner,address adminwhitelised );
    event UserWhitelistd(address whitlister,address userwhitelised );
    event AdminRemoved(address removedby,address adminremoved);
    event UserRemoved(address removedby,address userremoved);
    event UpdatedBaseUrl(address updatedby);
    event MintingLimitUpdated(address updatedby,uint limit);

    // Custom Erros

    error NotEqualToTotalLimit();
    error WhitelistedAdminAllowed();
    error PriceError();
    error MintingPaused();
    error PublicSaleActive();
    error PublicSaleUnactive();
    error NotWhitelistedUser(address _address);
    error AdminNotFound(address _address);
    error TotalLimitReached(uint256 limit);
    error MintingLimitReached(uint256 limit);
    error UserLimitReached(address addrs, uint256 limit);
    error PleaseCheckValue(uint256 limit);
    error AlreadyActive(string status);
    error AdminOrIdAlreadyExist(address addrs,uint Id);
    error WUserAlreadyExist(address addrs,uint Id);
    error IdNotFound(uint Id);

    modifier onlyAdmins {
        if(isAdmin[msg.sender] == false) revert AdminNotFound(msg.sender);
        // require(isAdmin[msg.sender] == true, "Only Admin Allowed");
        _;
    }

    function becomeAdmin(address _address,string memory _name, uint _setAdminId)public payable{
        if(isAdmin[_address] == true || adminIdCheck[_setAdminId] == true) revert 
        AdminOrIdAlreadyExist(_address,_setAdminId);
        // uint amoumt = (msg.value / price) * 1 wei;
        if( msg.value == adminPrice){
        (bool success,) = payable(cOwner).call{value: msg.value}("");
        if(success == false) revert PriceError();
        
   
        // for(uint i = 0;i < myy.length;i++){
        //      myy.push(_address);

        // }
        adminsCount++;
       
        adminDetails[_address] = admininfo(_name,_setAdminId);
        isAdmin[_address] = true;
        adminIdCheck[_setAdminId] = true;
        adminsRecord[adminsCount] = adminsrecord(_address,_name);

        }else{
            revert PriceError();
        } 
    }

    function unSubAdmin(uint _adminId)public onlyAdmins{
        if(adminIdCheck[_adminId] == false) revert 
        IdNotFound(_adminId);
        delete adminDetails[msg.sender];
        isAdmin[msg.sender] = false;
        adminIdCheck[_adminId] = false;
        delete WhitelistedUser[_adminId];
        delete checkWhitelistedUser[_adminId][msg.sender];
        mintingLimits[_adminId].totalLimit = 0 ;
        mintingLimits[_adminId].whitelistLimit = 0 ;
        mintingLimits[_adminId].PlatformLimit = 0 ;
        mintingLimits[_adminId].publicLimit = 0 ;

    }

    function setMintingLimits(uint256 _adminId,uint256 _totallimit,uint256 _whitelistlimit, uint256 _platformlimit)public onlyAdmins{
        if (_whitelistlimit + _platformlimit <= _totallimit) {
            mintingLimits[_adminId].totalLimit = _totallimit;
            mintingLimits[_adminId].whitelistLimit = _whitelistlimit;
            mintingLimits[_adminId].PlatformLimit = _platformlimit;
            mintingLimits[_adminId].publicLimit = _totallimit - (_whitelistlimit + _platformlimit);
        } else {
             revert NotEqualToTotalLimit();
         }
            
    }

    function setAdminPrice(uint _price)public onlyOwner{
         adminPrice =  _price;
         adminPrice = adminPrice / (1 wei);
        
    }
   

    // All Miniting Functions

    /**
     * @dev userMinting is used to mint the Nfts for whitelidted users.
     * userMinting will not work if public sales are active.
     * Once user limit reached then user will not allowd to mint
     * Requirement:
     * - This function can only called by whitelidted users.
     * @param to- reciver address
     * @param tokenId- nft Id 
     * @param _name- name 
     * @param _metadataHash - metadatahash
     * Emits a {WhitlistUserMinited} event.
    */  
    

    function whitelistMinting(
        address to,
        uint256 tokenId,
        string memory _name,
        uint _adminId,
        string memory _metadataHash
    ) public {
        if (mintingStatus == false) 
        revert MintingPaused();
        if (publicSaleBool == true) 
        revert PublicSaleActive();
        if (isWhitelistedUser[msg.sender] == false) 
        revert NotWhitelistedUser(msg.sender);
        if (totalLimitCount >= mintingLimits[_adminId].totalLimit) 
        revert TotalLimitReached(mintingLimits[_adminId].totalLimit);
        if (mintingLimits[_adminId].whitelistLimit <= 0) 
        revert MintingLimitReached(totalwhitelistLimit);
        if (userMintedStatus[msg.sender] >= userLimit)
        revert UserLimitReached(msg.sender, userLimit);
        if(checkWhitelistedUser[_adminId][msg.sender] == false)
        revert NotWhitelistedUser(msg.sender);

        _safeMint(to, tokenId);
        nftData[tokenId] = nftinfo(_name, _metadataHash);
        totalLimitCount++;
        mintingLimits[_adminId].whitelistLimit--;
        userMintedStatus[msg.sender]++;
        emit WhitlistUserMinited(msg.sender,to,tokenId,_name);
    }

    /**
     * @dev publicMinting is used to mint the Nfts for public. 
     * publicMinting only available when public sales are active.
     * Requirement:
     * @param to- reciver address
     * @param tokenId- nft Id 
     * @param _name- name 
     * @param _metadataHash - metadatahash
     * Emits a {PulblicUserMinited} event.
    */

    function publicMinting(
        address to,
        uint256 tokenId,
        string memory _name,
        uint _adminId,
        string memory _metadataHash
    ) public {
        if (mintingStatus == false) 
        revert MintingPaused();
        if (publicSaleBool == false)
         revert PublicSaleUnactive();
        if (totalLimitCount >= mintingLimits[_adminId].totalLimit)
         revert TotalLimitReached(mintingLimits[_adminId].totalLimit);
        if ( mintingLimits[_adminId].publicLimit <= 0)
         revert MintingLimitReached(totalPublicLimit);
        if (userMintedStatus[msg.sender] >= userLimit)
        revert UserLimitReached(msg.sender, userLimit);

        _safeMint(to, tokenId);
        nftData[tokenId] = nftinfo(_name, _metadataHash);
        totalLimitCount++;
        mintingLimits[_adminId].publicLimit--;
        userMintedStatus[msg.sender]++;
        emit PulblicUserMinited(msg.sender,to,tokenId,_name);
    }

    /**
     * @dev platformMinting is for admin minting. 
     * admin will allowd to mint assigned limit by contract and no other ristrictions.
     * Requirement:
     * @param to- reciver address
     * @param tokenId- nft Id 
     * @param _name- name 
     * @param _metadataHash - metadatahash
     * Emits a {PulblicUserMinited} event.
    */

    function platformMinting(
        address to,
        uint256 tokenId,
        string memory _name,
        uint _adminId,
        string memory _metadataHash
    ) public {
        if (isWhitelistedAdmin[msg.sender] == false)
         revert AdminNotFound(msg.sender);
        if (totalLimitCount >= mintingLimits[_adminId].totalLimit)
         revert TotalLimitReached(mintingLimits[_adminId].totalLimit);
        if (mintingLimits[_adminId].PlatformLimit <= 0)
         revert MintingLimitReached(totalPlatformLimit);
  

        _safeMint(to, tokenId);
        nftData[tokenId] = nftinfo(_name, _metadataHash);
        totalLimitCount++;
        mintingLimits[_adminId].PlatformLimit--;
        emit AdminMinited(msg.sender,to,tokenId,_name);
    }

    function tokenURI(uint256 tokenId) public view override
    (ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(baseURI, nftData[tokenId].Hash));
    }

    /**
     * @dev updateBaseurl is used to update Baseurl.
     * Requirement:
     * - This function can only called by whitelisted admin
     * @param _Url - new Baseurl 
     * Emits a {UpdatedBaseUrl} event.
    */

    function updateBaseurl(string memory _Url) public {
        if (isWhitelistedAdmin[msg.sender] == false)
        revert AdminNotFound(msg.sender);
        baseURI = _Url;
        emit UpdatedBaseUrl(msg.sender);
    }

    /**
     * @dev updateMintingLimit is used to update all user limits.
     * Requirement:
     * - This function can only called by whitelisted admin
     * @param limit - new limit
     * Emits a {MintingLimitUpdated} event.
    */

    function updateMintingLimit(uint256 limit) public {
        if (isWhitelistedAdmin[msg.sender] == false) 
        revert AdminNotFound(msg.sender);
        if (limit <= 0) revert PleaseCheckValue(limit);
        userLimit = limit;
        emit MintingLimitUpdated(msg.sender,limit);
    }

    /**
     * @dev whitelistUser is used to whitelist the users.
     * Requirement:
     * - This function can only called by whitelisted admin
     * @param _address - user address
     * Emits a {UserWhitelistd} event.
    */

    function whitelistUser(uint _adminId,address _address) public onlyAdmins{
        if(adminDetails[msg.sender].adminId != _adminId)
         revert IdNotFound(_adminId);
        if(checkWhitelistedUser[_adminId][_address] == true)
        revert WUserAlreadyExist(_address,_adminId);
         address[] storage users = WhitelistedUser[_adminId];
         users.push( _address);
        WhitelistedUser[_adminId] = users;
        checkWhitelistedUser[_adminId][_address] = true;
        isWhitelistedUser[_address] = true;
        emit UserWhitelistd(msg.sender,_address);
    }

    function whitelistUsers(uint adminId)public view returns(address[] memory){
        return WhitelistedUser[adminId];
  
    }

    /**
     * @dev removeWUser is used to remove the Whitelistd User.
     * Requirement:
     * - This function can only called by owner of the contract
     * @param _address -  admint address
     * Emits a {UserRemoved} event.
    */
    
    // function removeWUser(address _address) public onlyOwner{
    //     if( isWhitelistedUser[_address] == false) 
    //     revert NotWhitelistedUser(_address);
    //     isWhitelistedUser[_address] = false;
    //     emit UserRemoved(msg.sender,_address);
    // }

    /**
     * @dev whitelistAdmin is used to whitelist the admin.
     * Requirement:
     * - This function can only called by owner of the contract
     * @param _address - new admint address
     * Emits a {AdminWhitelisted} event.
    */

    // function whitelistAdmin(address _address) public onlyOwner{
    //     isWhitelistedAdmin[_address] = true;
    //     emit AdminWhitelisted(msg.sender,_address);
    // }

    /**
     * @dev removeWAdmin is used to remove the admin.
     * Requirement:
     * - This function can only called by owner of teh contract
     * @param _address -  admint address
     * Emits a {AdminRemoved} event.
    */

    // function removeWAdmin(address _address) public onlyOwner{
    //     isWhitelistedAdmin[_address] = false;
    //     emit AdminRemoved(msg.sender,_address);
    // }

    /**
     * @dev publicSalesActDis is used to activate and disable the public sales.
     * Requirement:
     * - This function can only called by owner of teh contract
    */

    // function publicSalesActDis() public onlyOwner{    
    //     if(publicSaleBool == false){
    //     publicSaleBool = true;
    //     publicSales = 'Active';
    //     totalPublicLimit = (publicLimitLeft + whitelistLimitLeft);
    //     publicLimitLeft = (publicLimitLeft + whitelistLimitLeft);
    //     whitelistLimitLeft = whitelistLimitLeft * 0 ;
    //     }else{
    //     publicSaleBool = false;
    //     publicSales = 'Disabled';
    //     }
      
    // }

    /**
     * @dev mintingPusAct is used to activate and pause minting.
     * Requirement:
     * - This function can only called by owner of teh contract
    */

    function mintingPusAct() public onlyOwner {
        if(mintingStatus == false){
        // mintingBool = true;
        mintingStatus = true;
        }else{
        // mintingBool = false;
        mintingStatus = false;
        }
        
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
