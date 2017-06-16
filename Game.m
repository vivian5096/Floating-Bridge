classdef Game <handle
    properties
        trick_no
        turn % 1(leader)->4(last person) to play
        leader
        leading_suit
        cards_played %(1X4 Cards object array)
        players_turn % which player no. turn
        winner
        %trumped
    end
    methods
        function round = Game(n)%leader,leading_suit,player_turn,winner)
            round.trick_no=n;
            round.leader=0;%leader;
            round.leading_suit=0;%leading_suit;
            round.cards_played=[Cards(1,1,1) Cards(1,1,1) Cards(1,1,1) Cards(1,1,1)];%cards_played;
            round.players_turn=0;%player_turn;
            round.winner=0;%winner;
        end
        function reset_Game(round)
            round.leader=0;%leader;
            round.leading_suit=0;%leading_suit;
            round.cards_played=[Cards(1,1,1) Cards(1,1,1) Cards(1,1,1) Cards(1,1,1)];%cards_played;
            round.players_turn=0;%player_turn;
            round.winner=0;%winner;
        end
    end
end