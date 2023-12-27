// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleStorage{
    // basic data types
    // boolean
    // uint
    // int
    // string
    // address
    // bytes

    // Storage types , solidity can store data in 6 types
    // memory (temporary variables which can be verified)
    // calldata (temporary variables which cannot be verified)
    // storage (permanent storage)
    // stack
    // code 
    // logs



    uint256  myFavouriteNumber;
    // list of favouriteNumbers
    uint256[] favouriteNumbers;
    // struct data type for custom data type
    struct Person{
        uint FavouriteNumber;
        string name;
    }

    // list of persons
    Person[] public listOfPeople;

    function store(uint256 _newFavouriteNumber) public{
        myFavouriteNumber=_newFavouriteNumber;
    }

    // view function identifier means you cannot change state 
    function showFavouriteNumber() public view returns(uint256){
        return myFavouriteNumber;
    }

    // pure function means it is not even reading from the blockchain , like returning a constant or doing some calculation
    function pureFunction(uint a) public pure returns (uint256){
        return 10+a;
    }

    // manipulating person struct
    function addPerson(string memory _name, uint _number) public {
        // method 1 of doing this
        // Person memory newPerson= Person(_number,_name);
        // listOfPeople.push(newPerson);

        // method 2 of doing this
        // Person memory newPerson= Person({name:_name,FavouriteNumber:_number});
        // listOfPeople.push(newPerson);

        // method 3 of doing this
        // listOfPeople.push(Person(_number,_name));

        // method 4 of dpoing this
        listOfPeople.push(Person({name:_name,FavouriteNumber:_number}));
    }
}

