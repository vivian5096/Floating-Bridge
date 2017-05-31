**Floating Bridge**
=============================


> Hi! So this is Floating Bridge, aka Singaporean Bridge

**Rule of The Game**
- The game starts off with the Biding Phase where you bid for the number of sets you and your partner should win (6 + number of bid) and the suit that you want to be the trump suit of the game
- In this game, Clubs is the lowest of all suits, followed by Diamonds, Hearts, Spades and No trump
- Players can only bid higher (eg. If the current bid is 1 Hearts and the next player would like to bid Clubs, he/she will have to bid 2 Clubs or higher)
- When there are 3 passes, the winner of the bid wil become the declarer
- This is when things differ between Floating Bridge and normal contract bridge
- The declarer now must specify a card of other players to be his/her partner. The partner will not be revealed until that card is played
- After this, the game starts and the method of winning a trick is the same as normal contract bridge
- PLayers must follow suit as long as they still have cards of the leading suit of that trick
- The highest valued card (2 is the lowest while A is the highest) of the leading suit will win the trick unless a trump is played
- In that case, the highest valued trump card will win the trick
- Trump must not be played as the leading suit until trump is broken - a trump card is played in a trick when the player has run out of the leading suit OR when the player has only trump cards left in his/her hand
The winning team of the game will be the team who makes the bid that was set in the bidding phase. Declarer win set is (6 + bid number) while the defenders win set is (8 - bid number)

In order to play this game, you must load all the files here except Vibot1 which is a AI class in progress.
Before you run, make sure that the player type in Singbridge is set to the right type of players (Human, randomAI or Vibot1 - if you load it). Vibot1 and randomAI runs the same algorithm at the moment. At this point, the game play of the AI are still random.

Singbridge.m
----------
This is the main file of the game which you should run.
Here are a few things which you can change:-
1. Background colour - takes in normalized RGB values
2. Player type - Human, randomAI or Vibot1
   - For better visual experience it is recommended that you choose player 1 as human. However you can also set other players to human if you so wish
3. see_all_deck can be change to 0 if you would like to see all the hands of the players (cheating?)
4. win.UserData.game_delay (seconds) can also be changed to make the pause between game shorter or longer. 0.5s (default) 
----------


Table.m
-----
Properties
- **state** [*doubles*]: 0-dealing cards 1-bidding phase 2-choose partner 3-main game
- **scores** [1X4 *doubles array*]: score board
- <i class="icon-shield"></i>**players** [1X4 *array* of Player objects]   
- <i class="icon-shield"></i>**bid** [*doubles*]: current bid (eg.45 = 4 No Trump)
- <i class="icon-shield"></i>**trump_suit**[*doubles*] :1-5
- <i class="icon-shield"></i>**partner_card**[*doubles*] : (eg. 114)
- <i class="icon-shield"></i>**declarer_win_set**[*doubles*] : 6+bid
- <i class="icon-shield"></i>**defender_win_set**[*doubles*] : 8-bid
(Event)
- <i class="icon-shield"></i>**trump_broken**[*double*] : 1- broken; 0 - not broken
(Players' Role)
- <i class="icon-shield"></i>**declarer**[*doubles*] : player's no.
- <i class="icon-shield"></i>**declarer_partner**[*doubles*] : to be updated when partner card is revealed
- <i class="icon-shield"></i>**defenders**[1X2 *doubles array*] : to be updated when partner card is revealed

Functions

**Table** 
Constructor; Input: players, state, scores

**bidding_Process**
>- **Input :** suit_name, score_text, message_text, win, bidsuit_button, bidnum_button, display_bidnum, display_bidsuit, bid_button, pass_button, player_text
>- **Output:** nil
>- **Structure**:-
>  1. Randomly determine first bidder 
>  2. Obtain bid from players *(fn: Player.place_Bid() )* until there are 3 passes
>  3. Name the declarer *(fn: Player.name_Declarer() )*
>  4. Update table properties: trump_suit, declarer_win_set and defender_win_set
>- **Local Variables**:-
> 1. first_bidder
> 2. counter : keep track of bidding turns
>  3. no_of_pass 
>  4. pl.bids [*doubles array*]
>  5. i : convert counter into player no.
>  6. j : convert counter into no. of rounds of bidding
>  7. suitind : index of the suit convert suitind of 0 to 5
>  8. bid_name [*string*]

**call_Partner**
Ask declarer to choose a partner *(fn: Player.choose_Partner())*

**first_Leader**
Determine leader of the first trick. 
Rule : Player left of declarer start if there is a trump suit and Declarer starts if there is no trump suit

**trick**
> - Play out every trick
>- **Input :** game, message_text, role_text, player_hand_deck, disp_axes, player_played_card, win, msg2, player_text
>- **Output:** next_leader
>- **Structure**:-
>  1.  Players play cards *(fn: Player.play_Card)*
>  2. Select a card on the player_hand_deck cardholder
>  3. Transfer that card to the player_played_card cardholder *(fn: Cardholder.transfer_Selected_Cards() )*
>  4. Update the Graphics of both cardholders
>  5. Check if partner's card is played. If yes, update the table partner and defender properties and notify the players *(fn: Player.update_Players_Partner())*
>  6. If leader's turn, update the leading suit
>  7. Repeat until all players had their turn 
>  8. Decide winner: Check if anyone trumped. If yes, player who played the highest trump card is the winner. If not, player who played the highest leading suit card is the winner
>  9. Update players' memory *(fn: Player.update_Memory)*
>  10. Clear the player_played_card cardholder
>- **Local Variables**:-
> 1. counter : determines the player no. of current player
> 2. non_declarer
>   3. non_declarerpartner
>   4. suit_played [1X4 *doubles array*]
>   5. follow_suit_played

**who_Win** 
Determines the winning team and the no. of set won above bid
> **Local Variables**: declarer_team_score, defender_team_score

<i class="icon-tag"></i> **init_cards** 
Load 52 Card objects into all_cards

<i class="icon-tag"></i> **shuffle** 
Input : all_cards, method (optional). If method == 1, manually input cards. Output: Decks (sorted)


----------


Player.m
--------
Properties 
- <i class="icon-shield"></i>**num** : Player's no.
- <i class="icon-shield"></i>**type** : Human/ randomAI/ Vibot1
- <i class="icon-shield"></i>**hand** : 13 cards [Card objects]
- <i class="icon-shield"></i>**role** : Declarer/Partner/Defender
- <i class="icon-shield"></i>**partner**: player's partner's no.
- <i class="icon-shield"></i>**points**: points of player's hand
(Memory of AI player)
- <i class="icon-shield"></i>**memory_bid**
- <i class="icon-shield"></i>**memory_cards_played**
(Belief of AI)
- <i class="icon-shield"></i>**belief_partner**
- <i class="icon-shield"></i>**belief_carddist**
(AI Specific Variables)
- <i class="icon-shield"></i>**w_a**
- <i class="icon-shield"></i>**w_b**
Functions

**Player** 
> Constructor
> Input: type, num, cards
> Load saved mat. file for certain AI type to retrieve variables

**update_Hand**
> Update hand of players

determine_Point
> Update points of player
> **Local Variables**:-
> - cards_value[1X13 *doubles array*] : eg. 114
> - cards_suits [1X13 *doubles array*] : 1,...4
> - cards_num [1X13 *doubles array*] : 2,...,13,14
> - points_jqka [1X4 *doubles array*] : points in every suit
> - no_of_cards_in_each_suit [1X4 *doubles array*] 
> - five_of_a_kind [*doubles*]

check_Point
> Ask player for reshuffle request if its points are less than 4 
> Pass AI player and state to getAction
> Input : message_text, choice_button, win
> **Local Variables**: request_reshuffle

place_Bid
> Ask players for bid and update memory of players regarding bid history
> Pass AI player, state, current_bid and loss reward factor (0.3)
> Input : tb.bid (current bid), pl_bid, win, bidsuit_button, bidnum_button, display_bidnum, display_bidsuit, bid_button, pass_button
> Output: bid

**name_Declarer**
> Update player who is the declarer's role

choose_Partner
> Ask players for bid and update memory of players regarding bid history
> Pass AI player, state, table.trump_suit and all_cards
> Input : all_cards, tb, win, message_text, partner_button, call_button, bidsuit_button, display_bidnum, display_bidsuit
> Output: card_selected [Card object]

**identify_Role**
> Update non-declarer players' role according to the partner card
> Input : tb.partner_card, tb.declarer

play_Card
> Pass AI player, state, game(no_of_trick).leading_suit and tb
> Input : game(no_of_trick), tb, win, player_hand_deck
> Output: card_played [Card object], selected_card_ind (card index on the player's hand)

update_Players_Partners
> Input : tb.declarer_partner, tb.defenders

update_Memory
> Input : game(no_of_trick)


Game.m
--------
Properties 
-  **trick_no**
- **turn** : 1(leader)->4(last person) to play
- **leader**
- **leading_suit**
- **cards_played** [1X4 Cards object array]
- **players_turn** which player no. turn
- **winner**

Functions
**Game** 
> Constructor; Input: no_of_trick

Cards.m
--------
Properties 
- <i class="icon-shield"></i> **value**
- <i class="icon-stop"></i>**image_data**
- <i class="icon-stop"></i>**backimage_data**

Functions
**Cards** 
> Constructor; Input: value, image_data, backimage_data
**get_Card_Image** 
> Input: card, side ('front' or 'back')
> Output: img_data[1X3 *double array*]<!--se_discussion_list:{"fkEvaJZyx6iaHXhcx5p2Ue2a":{"selectionStart":3660,"selectionEnd":3672,"commentList":[{"content":"Takes up memory"}],"discussionIndex":"fkEvaJZyx6iaHXhcx5p2Ue2a"}}-->
