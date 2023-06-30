pragma solidity ^0.8.0;

contract Blackjack {
    address public owner;
    uint public minimumBet;
    uint public maximumBet;
    uint public deckSize;
    uint public dealerThreshold;
    
    mapping(address => uint) public balances;
    mapping(address => uint) public bets;
    mapping(address => uint[] ) public playerCards;
    bool public gameStarted;
    address[] public players;
    uint[] private deck;
    uint public dealerCard;
    uint public dealerScore;
    uint public numPlayers;
    
    event GameStarted(address dealer);
    event CardDealt(address player, uint card);
    event GameEnded(string outcome, address[] winners, uint[] rewards);

    constructor(uint _minimumBet, uint _maximumBet, uint _deckSize, uint _dealerThreshold) {
        owner = msg.sender;
        minimumBet = _minimumBet;
        maximumBet = _maximumBet;
        deckSize = _deckSize;
        dealerThreshold = _dealerThreshold;
        deck = new uint[](deckSize);
    }
    
    function startGame() public {
        require(msg.sender == owner);
        require(!gameStarted);
        gameStarted = true;
        dealerCard = 0;
        dealerScore = 0;
        numPlayers = players.length;
        shuffleDeck();
        emit GameStarted(owner);
    }
    
    function placeBet(uint _bet) public {
        require(gameStarted);
        require(_bet >= minimumBet && _bet <= maximumBet);
        require(balances[msg.sender] >= _bet);
        balances[msg.sender] -= _bet;
        bets[msg.sender] += _bet;
        players.push(msg.sender);
    }
    
    function dealCard(address _player) private {
        uint card = deck.pop();
        playerCards[_player].push(card);
        emit CardDealt(_player, card);
    }
    
    function dealDealerCard() private {
        uint card = deck.pop();
        dealerCard = card;
        dealerScore = getCardValue(card);
    }
    
    function getCardValue(uint card) private pure returns (uint) {
        return card % 13 + 1;
    }
    
    function getPlayerScore(address _player) public view returns (uint) {
        uint score = 0;
        for (uint i = 0; i < playerCards[_player].length; i++) {
            score += getCardValue(playerCards[_player][i]);
        }
        return score;
    }
    
    function stand() public {
        require(gameStarted);
        
        while (dealerScore < dealerThreshold) {
            dealDealerCard();
        }
        
        uint dealerScoreWithAce = dealerScore;
        if (dealerScore <= 11) {
            dealerScoreWithAce += 10;
        }
        
        // Determine winner(s) and distribute rewards accordingly
        address[] memory winners;
        uint[] memory rewards;
        uint numWinners = 0;
        for (uint i = 0; i < players.length; i++) {
            address player = players[i];
            uint playerScore = getPlayerScore(player);
            
            if (playerScore <= 21) {
                uint playerScoreWithAce = playerScore;
                if (playerScore <= 11) {
                    playerScoreWithAce += 10;
                }
                
                if (playerScoreWithAce > dealerScoreWithAce || dealerScore > 21) {
                    uint reward = bets[player] * 2;
                    balances[player] += reward;
                    rewards[numWinners] = reward;
                    winners[numWinners] = player;
                    numWinners++;
                } else if (playerScore == dealerScoreWithAce) {
                    balances[player] += bets[player];
                    rewards[numWinners] = bets[player];
                    winners[numWinners] = player;
                    numWinners++;
                } 
            }
            
            bets[player] = 0;
            playerCards[player] = new uint[](0);
        }
        
        players = new address[](0);
        gameStarted = false;
        
        emit GameEnded("Finished", winners, rewards);
    }
    
    function shuffleDeck() private {
        uint randNonce = 0;
        
        for (uint i = 0; i < deckSize; i++) {
            uint randIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % (deckSize - i) + i;
            uint temp = deck[randIndex];
            deck[randIndex] = deck[i];
            deck[i] = temp;
            randNonce++;
        }
    }
    
    function deposit() public payable {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint amount) public {
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed.");
    }
    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}


