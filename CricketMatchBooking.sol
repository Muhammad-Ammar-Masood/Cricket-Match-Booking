// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract CricketMatchBooking {

    event Schedule(address scheduler, string matchTitle, string venue, uint time, uint price, uint ticketsTotal, uint ticketRemain);
    event BuyTicket(address buyer, uint id, uint quantity);
    event RevokeTicket(address sender, uint id, uint quantity);


    struct Match {
        address scheduler;
        string matchTitle;
        string venue;
        uint time;
        uint price;
        uint ticketsTotal;
        uint ticketsRemaining;
    }

    mapping(uint => Match) public matches;
    mapping(address => mapping(uint => uint)) public tickets;
    uint public matchId;

    function scheduleMatch(string calldata matchTitle, string calldata venue, uint time, uint price, uint ticketsTotal) external {
        require(time > block.timestamp, "set time for future");
        require(ticketsTotal > 0, "Tickets should be more than 0");

        matches[matchId] = Match(msg.sender, matchTitle, venue, time, price, ticketsTotal, ticketsTotal);
        emit Schedule(msg.sender, matchTitle, venue, time, price, ticketsTotal, ticketsTotal);
        matchId++;
    }

    modifier matchCheck(uint id) {
        require(matches[id].time != 0, "Match not schedule");
        require(matches[id].time > block.timestamp, "Match Passed");
        _;
    }

    function buyTicket(uint id, uint quantity) external payable matchCheck(id)  {
        Match storage _match = matches[id];
        require(msg.value >= (_match.price*quantity), "Not enough ethers");
        require(quantity <= _match.ticketsRemaining, "Not enough tickets");
        uint change = msg.value - _match.price*quantity;
        if(change != 0) {
            (bool success, ) = msg.sender.call{value: change}("");
            require(success, "failed");
        }
        _match.ticketsRemaining -= quantity;
        tickets[msg.sender][id] += quantity;
        emit BuyTicket(msg.sender, id, quantity);
    }

    function revokeTicket(uint id, uint quantity) external matchCheck(id) {
        Match storage _match = matches[id];
        require(tickets[msg.sender][id] >= quantity, "Not have enough tickets");
        (bool success, ) = msg.sender.call{value: _match.price*quantity}("");
        require(success, "failed");
        tickets[msg.sender][id] -= quantity;
        _match.ticketsRemaining += quantity;
        emit RevokeTicket(msg.sender, id, quantity);

    }

}
