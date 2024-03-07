// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BGV {
    // Struct to represent a document
    struct Document {
        string name;
        string hashValue;
    }

    // Struct to represent a student
    struct Student {
        string name;
        address studentAddress;
        address addedBy; // Address of the person who added the student
        Document[] documents; // Array of documents associated with the student
    }

    // Struct to represent a university
    struct University {
        string name;
        address universityAddress;
        string licenseNumber;
        bool approvedByGovernment;
    }

    // Mapping to store students by their Ethereum address
    mapping(address => Student) public students;

    // Mapping to store universities by their Ethereum address
    mapping(address => University) public universities;

    // Mapping to store license numbers to prevent duplicates
    mapping(string => bool) public licenseNumbers;

    // Mapping to store university addresses to prevent duplicates
    mapping(address => bool) public universityAddresses;

    // Event to emit when a new student is added
    event StudentAdded(address indexed studentAddress, string name, address indexed addedBy);

    // Event to emit when a new document is added to a student
    event DocumentAdded(address indexed studentAddress, string documentName, string hashValue);

    // Event to emit when a new university is added
    event UniversityAdded(address indexed universityAddress, string name);

    // Modifier to ensure only the student can access their document details
    modifier onlyStudent(address _studentAddress) {
        require(msg.sender == _studentAddress, "Only the student can access their own documents");
        _;
    }

    // Modifier to ensure only a legitimate university can add a student
    modifier onlyLegitimateUniversity(address _universityAddress) {
        require(universities[_universityAddress].approvedByGovernment && bytes(universities[_universityAddress].licenseNumber).length > 0, "Only a legitimate university can add a student");
        _;
    }

    // Function to add a new student
    function addStudent(string memory _name, address _studentAddress ) public onlyLegitimateUniversity(msg.sender) {
        // Ensure the student does not already exist
        require(students[_studentAddress].studentAddress == address(0), "Student already exists");

        // Create a new student
        Student storage newStudent = students[_studentAddress];
        newStudent.name = _name;
        newStudent.studentAddress = _studentAddress;
        newStudent.addedBy = msg.sender; // Changed to university address

        // Emit an event to notify that a new student has been added
        emit StudentAdded(_studentAddress, _name, msg.sender);
    }

    // Function to add a document to an existing student
    function addDocumentToStudent(address _studentAddress, string memory _documentName, string memory _hashValue) public onlyStudent(_studentAddress) {
        // Ensure the student exists
        require(students[_studentAddress].studentAddress != address(0), "Student does not exist");

        // Check if a document with the same hash value already exists
        for (uint i = 0; i < students[_studentAddress].documents.length; i++) {
            if (keccak256(abi.encodePacked(students[_studentAddress].documents[i].hashValue)) == keccak256(abi.encodePacked(_hashValue))) {
                revert("Document already exists");
            }
        }

        // Create a new document
        Document memory newDocument = Document({
            name: _documentName,
            hashValue: _hashValue
        });

        // Add the document to the student's array
        students[_studentAddress].documents.push(newDocument);

        // Emit an event to notify that a new document has been added to the student
        emit DocumentAdded(_studentAddress, _documentName, _hashValue);
    }

    // Function to add a new university
    function addUniversity(string memory _name, address _universityAddress, string memory _licenseNumber, bool _approvedByGovernment) public {
        // Ensure the university address is unique
        require(!universityAddresses[_universityAddress], "University address already exists");

        // Ensure the license number is unique
        require(!licenseNumbers[_licenseNumber], "License number already exists");

         // Ensure the university is approved by the government
        require(_approvedByGovernment, "University must be approved by the government");

        // Create a new university
        University storage newUniversity = universities[_universityAddress];
        newUniversity.name = _name;
        newUniversity.universityAddress = _universityAddress;
        newUniversity.licenseNumber = _licenseNumber;
        newUniversity.approvedByGovernment = _approvedByGovernment;

        // Mark the license number and university address as used
        licenseNumbers[_licenseNumber] = true;
        universityAddresses[_universityAddress] = true;

        // Emit an event to notify that a new university has been added
        emit UniversityAdded(_universityAddress, _name);
    }

    // Function to verify if a university is legitimate
    function isUniversityLegitimate(address _universityAddress) public view returns (bool) {
        return universities[_universityAddress].approvedByGovernment && bytes(universities[_universityAddress].licenseNumber).length > 0;
    }

    // Function to get the count of documents for a student
    function getDocumentCount(address _studentAddress) public view returns (uint) {
        return students[_studentAddress].documents.length;
    }

    // Function to get the details of all documents for a student
    function getDocumentDetails(address _studentAddress) public view onlyStudent(_studentAddress) returns (string[] memory, string[] memory) {
        uint documentCount = students[_studentAddress].documents.length;

        string[] memory documentNames = new string[](documentCount);
        string[] memory hashValues = new string[](documentCount);

        for (uint i = 0; i < documentCount; i++) {
            Document memory doc = students[_studentAddress].documents[i];
            documentNames[i] = doc.name;
            hashValues[i] = doc.hashValue;
        }

        return (documentNames, hashValues);
    }
}
