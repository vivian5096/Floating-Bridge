**Floating Bridge**
=============================


> **Note**:-
> Documentation is for version 2 of the game

Conventions
-----------

 1. Variable names are named without capitals
 2. Function names are named with capitals after the first word 
 3. <i class="icon-globe"></i> - global variables
 4. <i class="icon-picture"></i> - graphic related functions
 5. <i class="icon-refresh"> </i> - Callback functions
 6. <i class="icon-tag"></i> - Static functions
 7. <i class="icon-shield"></i> - Properties with SetAccess =Private
 8.  <i class="icon-stop"></i> - Properties with Access =Private

----------


Singbridge.m
----------
###Structure
#####Setting up the game
 1. Start by calling Singbridge (choose to get seed or not) 
 2. Get information about the screen 
 3. Define settings 
 4. Construct the window
 5. Initialize all cards
 6. Prepare playfield and drawing axes 
 7. Initialize players objects
 8. Draw graphics and UIcontrols 
	 - Functions: draw_Uicontrol, draw_Playfield
#####Start of the game
 9. Reset graphical settings
 10. Initialize table, **tb**
 11. Table state 0: Shuffling, Dealing out cards & request for reshuffle
	 1. Shuffle 
	 *(fn: Table.shuffle() )*
	 2. Distribute cards
	 3. Update Cardholder 
	 *(fn: Cardholder.append_Cards() )*
	 4. Update graphics 
	 *(fn: Cardholder.update_Deck_Graphics())*
	 5. Determine points 
	 *(fn: Player.determine_point() )*
	 6. Ask around for reshuffle requests 
	 *(fn: Player.check_Points() )*
	 7. Turn off buttons if turned on & reset graphics
	 8. If reshuffle, clear deck 
	 *(fn: Cardholder.clear_Deck() )*
	 9. Only accept request 3 times in a row
 12. Table state 1: Bidding Process 
 *(fn: Table.bidding_Process())* 
	 - Reset graphics
 13. Table state 2: Choose Partner 
 *(fn: Table.call_Partner() )*
	 - Reset graphics
	 - Other players identify themselves as partner or defenders 
	 *(fn: Player.identify_Role() )*
 14. Table state 3 : Start playing tricks
	 - Enable the ButtonDownFcn of win
	 - Initialize 13 games - Game objects
	 - Identify first player 
	 *(fn: Table.first_Leader() )*
	 - Run 13 tricks 
	 *(fn: Table.trick() )*
	 - Update table scores
	 - Disable the ButtonDownFcn of win after 13 tricks
 15. Declare winning team
 16. Ask whether to continue game
###Variables
####General variables
- **all_cards**[1X52 array of Card object]
- <i class="icon-globe"></i>**suit_name**[1X5 *strings array*]  - Clubs, Diamonds, Hearts, Spades, No Trump
- <i class="icon-globe"></i>**num_name**[1X13 *strings array*] - 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, A
- **seed** is the seed of rand operations in the game that can be retrieved in case anything peculiar happens and we want to rerun the scenario. The seed will overwrite over the seed of previous game. So only seed of last played game will be stored.
-  **tb** [Table Object]
- **no_times_dealt** [*doubles*]
- **request_reshuffle**[1X4 *doubles array*]
- **Decks**[4X13 *array* of Cards object] - dealt cards
- **msg1**[*string*] - on bid and trump suit
- **non_declarer** [1X3 *doubles aray*]
- **msg2**[*string*] - msg 1 and partner card
- **no_of_trick**[*doubles*]- counter for the no of tricks 1-13
- **game**[Game object] - for each no of trick
- **msg3**[*string*] - on winning team
- **continue_game**[*logical*] - yes(1) or no(1)


####GUI variables
- <i class="icon-globe"></i>**win** [*figure*] - window/ game console
> **Properties**:-
> - Name : Floating Bridge
> - Colour : [0 0.2 0]
> - MenuBar : none
> - ToolBar : none
> - Resize : off
> - ButtonDownFcn : check_clicked_deck (only activated in state 3 - the game loops)
-  **win.UserData** [*struct*]
>**game_delay** - pause when playing (set to 0.5s)
>**decision** - yes (1) and no (0) choices. 
>**humanbidresult** - pass(0) or bid no. & bid suit (eg.43 = 4 Hearts)
>**callpartner** - card value (eg. 104 = 4 Clubs, 311 = J Hearts)

- **scrsz** [1X4 *doubles array*]  - screen size
- **win_ratio** [1X2 *doubles array*]  - window ratio :    [width, height] / width 
-  **win_size** [1X2 *doubles array* ]  - window size 
- <i class="icon-globe"></i>**disp_axes** - get axes of the window
- **playfield_size** - [1X2 *doubles array*]
- **background_colour** - *RGB values* - colour of the window
- **text_colour** - *RGB values* - colour of player_text and score_text
- **role_text_colour** - *RGB values* - special colour of role_text
- **font_size** - font size of player_text, role_text, score_text, display_bidnum and display_bidsuit
- **see_all_deck** -  0 : All players' hand are displayed; 1 : AI players' hand are hidden
###### Cardholder objects
- **player_hand_deck** - [Cardholder object] contain all dealt player's cards
- **player_played_card** - [Cardholder object] contain the card played by the players
###### UIcontrol Variables
- **player_text** - display name of players (eg. randomAI, Vibot1, Human etc)
- **score_text** - display bid and score of each player
- **role_text** - display role of each player when known
- **message_text** - display all kind of message at the center of the UI
- **choice_button** - 'yes' or 'no'
- **bidsuit_button** 
-  **bidnum_button**
- <i class="icon-globe"></i>**display_bidnum** - display bid number or declarer's partner's card number
- <i class="icon-globe"></i>**display_bidsuit** - display bid suit or declarer's partner's card suit
- **bid_button**
- **pass_button**
- **partner_button** - partner card number
- **call_button**

### GUI Functions
#####<i class="icon-picture"></i> **prepare_playfield**
- Function to initialize cardholders and define playfield size
- Input : all_cards, win_ratio, see_all_deck
- Output : player_hand_deck, player_played_card, playfield_size
- Local variables : card_height, card_width, card_gap, border_offset, start_x, start_y, playfield_width, card_voffset and card_hoffset
#####<i class="icon-picture"></i> **draw_uicontrols**
- Function to draw uicontrols
- Input : all_cards, pl, playfield_size, background_colour, text_colour, role_text_colour, font_size
- Output : *all uicontrols*
- Local variables : card_height, card_width, card_voffset 
#####<i class="icon-picture"></i> **draw_playfield**
- Function to draw graphics of cardholders 
- Input : player_hand_deck, player_played_card
- Functions called : *cardholder*.update_Deck_Graphics, *cardholder*.render_deck_outline
##### Callback Functions :-
######<i class="icon-refresh"> **choice**
- Callback function of choice_button
- Assigns win.UserData.decision 
######<i class="icon-refresh"> **display_Bidnum**
- Callback function of bidnum_button
- Display bid number (1-7) on display_bidnum textbox
######<i class="icon-refresh"> **display_Bidsuit**
- Callback function of bidsuit_button
- Display suit (eg. Clubs) on display_bidsuit textbox
######<i class="icon-refresh"> **display_Partner_Cardnum**
- Callback function of partner_buttons
- Display card number (2,..,K,A) on display_bidnum textbox
######<i class="icon-refresh"> **bid_Passed**
- Callback function of pass_button
- Assigns win.UserData.humanbidresult = 0
######<i class="icon-refresh"> **bid_Entered**
- Callback function of bid_button
- Assigns win.UserData.humanbidresult
######<i class="icon-refresh"> **partner_Called**
- Callback function of call_button
- Assigns win.UserData.callpartner
#####<i class="icon-refresh"> **check_clicked_deck**
- Callback function of buttondownfn (when mouse clicked) of window
- Only allow left clicks
- Gets current mouse position (x,y), assigns win.UserData.Xx & win.UserData.Yy


----------


Table.m
-----
###Properties
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

###Functions
##### **Table** 
Constructor; Input: players, state, scores
#####**bidding_Process**
>- **Input :** suit_name, score_text, message_text, win, bidsuit_button, bidnum_button, display_bidnum, display_bidsuit, bid_button, pass_button, player_text
>- **Output:** nil
>- **Structure**:-
>	1. Randomly determine first bidder 
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

#####**call_Partner**
Ask declarer to choose a partner *(fn: Player.choose_Partner())*

#####**first_Leader**
Determine leader of the first trick. 
Rule : Player left of declarer start if there is a trump suit and Declarer starts if there is no trump suit

#####**trick**
> - Play out every trick
>- **Input :** game, message_text, role_text, player_hand_deck, disp_axes, player_played_card, win, msg2, player_text
>- **Output:** next_leader
>- **Structure**:-
>	1.  Players play cards *(fn: Player.play_Card)*
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

#####**who_Win** 
Determines the winning team and the no. of set won above bid
> **Local Variables**: declarer_team_score, defender_team_score

#####<i class="icon-tag"></i> **init_cards** 
Load 52 Card objects into all_cards
#####<i class="icon-tag"></i> **shuffle** 
Input : all_cards, method (optional). If method == 1, manually input cards. Output: Decks (sorted)


----------


Player.m
--------
###Properties 
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
###Functions

##### **Player** 
> Constructor
> Input: type, num, cards
> Load saved mat. file for certain AI type to retrieve variables

#####**update_Hand**
> Update hand of players

#####determine_Point
> Update points of player
> **Local Variables**:-
> - cards_value[1X13 *doubles array*] : eg. 114
> - cards_suits [1X13 *doubles array*] : 1,...4
> - cards_num [1X13 *doubles array*] : 2,...,13,14
> - points_jqka [1X4 *doubles array*] : points in every suit
> - no_of_cards_in_each_suit [1X4 *doubles array*] 
> - five_of_a_kind [*doubles*]

#####check_Point
> Ask player for reshuffle request if its points are less than 4 
> Pass AI player and state to getAction
> Input : message_text, choice_button, win
> **Local Variables**: request_reshuffle

#####place_Bid
> Ask players for bid and update memory of players regarding bid history
> Pass AI player, state, current_bid and loss reward factor (0.3)
> Input : tb.bid (current bid), pl_bid, win, bidsuit_button, bidnum_button, display_bidnum, display_bidsuit, bid_button, pass_button
> Output: bid

#####**name_Declarer**
> Update player who is the declarer's role

#####choose_Partner
> Ask players for bid and update memory of players regarding bid history
> Pass AI player, state, table.trump_suit and all_cards
> Input : all_cards, tb, win, message_text, partner_button, call_button, bidsuit_button, display_bidnum, display_bidsuit
> Output: card_selected [Card object]

#####**identify_Role**
> Update non-declarer players' role according to the partner card
> Input : tb.partner_card, tb.declarer

#####play_Card
> Pass AI player, state, game(no_of_trick).leading_suit and tb
> Input : game(no_of_trick), tb, win, player_hand_deck
> Output: card_played [Card object], selected_card_ind (card index on the player's hand)

#####update_Players_Partners
> Input : tb.declarer_partner, tb.defenders

#####update_Memory
> Input : game(no_of_trick)


Game.m
--------
###Properties 
-  **trick_no**
- **turn** : 1(leader)->4(last person) to play
- **leader**
- **leading_suit**
- **cards_played** [1X4 Cards object array]
- **players_turn** which player no. turn
- **winner**

###Functions
##### **Game** 
> Constructor; Input: no_of_trick

Cards.m
--------
###Properties 
- <i class="icon-shield"></i> **value**
- <i class="icon-stop"></i>**image_data**
- <i class="icon-stop"></i>**backimage_data**

###Functions
##### **Cards** 
> Constructor; Input: value, image_data, backimage_data
##### **get_Card_Image** 
> Input: card, side ('front' or 'back')
> Output: img_data[1X3 *double array*]<!--se_discussion_list:{"fkEvaJZyx6iaHXhcx5p2Ue2a":{"selectionStart":3660,"selectionEnd":3672,"commentList":[{"content":"Takes up memory"}],"discussionIndex":"fkEvaJZyx6iaHXhcx5p2Ue2a"}}-->
