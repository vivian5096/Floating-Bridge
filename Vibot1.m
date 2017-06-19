classdef Vibot1
    
    methods (Static)
        function action=getAction(player,state,var1,var2)
            narginchk(2, 5);
            switch state
                case 0
                    action=1;                                               % always request for reshuffle
                case 1
                    current_bid=var1;
                    estimate_wins=calculate([player.hand.value],player.w_a,player.w_b);
                    %disp(estimate_wins);
                    max_bid=ceil(estimate_wins)-3;
                    favourable_suit=find(estimate_wins==max(estimate_wins));
                    if length(favourable_suit)>1
                        favourable_suit=favourable_suit(randi(length(favourable_suit))); %input('wow! more than 1 favourable suit?')
                    end
                    %is current bid 0?
                    if current_bid==0
                        next_available_bid=10+favourable_suit;
                        action=next_available_bid;
                    else
                        bid_num=floor(current_bid/10); bid_suit=mod(current_bid,10);
                        % is current bid favourable?
                        if bid_suit==favourable_suit
                            if bid_num<max_bid(favourable_suit)
                                next_available_bid=10+current_bid;
                                action=next_available_bid;
                            else
                                action=0;
                            end
                        else
                            loss_reward=var2*((8-bid_num)-(max_bid(bid_suit)+1));
                            max_bid(favourable_suit)=max_bid(favourable_suit)+floor(loss_reward);
                            if favourable_suit<bid_suit
                                next_available_bid=bid_num*10+10+favourable_suit;
                            else
                                next_available_bid=bid_num*10+favourable_suit;
                            end
                            if floor(next_available_bid/10)<=max_bid(favourable_suit)
                                action=next_available_bid;
                            else
                                action=0;
                            end
                        end
                    end
                case 2
                    suit = floor([player.hand.value]/100);
                    num = mod([player.hand.value],100);
                    trump_suit=var1;
                    if sum(num(suit==trump_suit)==14)==0
                        cardnum_selected=trump_suit*100+14;
                    else
                        if sum(num(suit==trump_suit)==13)==0
                            cardnum_selected=trump_suit*100+13;
                        else
                            if sum(num(suit==trump_suit)==12)==0
                                cardnum_selected=trump_suit*100+12;
                            else
                                [~,weakest_suit]=min([sum(num(suit==1))*sum(suit==1) sum(num(suit==2))*sum(suit==2) sum(num(suit==3))*sum(suit==3) sum(num(suit==4))*sum(suit==4)]);
                                %disp(weakest_suit);
                                if length(weakest_suit)>1
                                    weakest_suit=weakest_suit(randi(length(weakest_suit))); input('wow! more than 1 weakest suit?')
                                end
                                options=[2 3 4 5 6 7 8 9 10 11 12 13 14];
                                ind = num(suit==weakest_suit)-1;
                                c = ones(1,13);
                                c(ind) = 0;
                                options=options(logical(c));
                                cardnum_selected=weakest_suit*100+max(options);
                            end
                        end
                    end
                    action=var2([var2.value]==cardnum_selected);
                case 3
                    
                    %play to maximise chance of winning or partner winning
                    tb=var2; round=var1;
                    leading_suit = round.leading_suit;
                    playable_cards = [player.hand.value];
                    suit = floor([player.hand.value]/100);
                    % Step 1: Get the playable_cards
                    if leading_suit == 0
                        disp('leading');
                        if tb.trump_broken==0 && any(suit ~= tb.trump_suit)
                            playable_cards = playable_cards(suit ~= tb.trump_suit);
                        end
                    else
                        disp('not leading')
                        if any(suit == leading_suit)
                            playable_cards = playable_cards(suit == leading_suit);
                        end
                    end
                    card_viability = ones(1,length(playable_cards));
                    nums = mod(playable_cards,100);
                    suit = floor(playable_cards/100);
                    [unique_suit,suit_count] = unique(suit,'stable');
                    suit_count = diff([suit_count' length(suit)+1]);
                    high_cards = max(player.memory_remaining_cards);
                    
                    % Debug purposes:
                    disp('Playable cards info: ')
                    disp(playable_cards);
                    disp('Value:')
                    disp(nums)
                    disp('Suit:');
                    disp(suit);
                    disp('Suit Count:')
                    disp(suit_count)
                    disp('Viability:');
                    disp(card_viability);
                    
                    % Step 2: Compute viability of the playable cards
                    %%%General viability
                    
                    % Viability of suits of low card count
                    disp('low card count cards')
                    low_suit = unique_suit(suit_count == min(suit_count));
                    disp(low_suit)
                    for i = low_suit
                    card_viability = card_viability + ...
                        (suit == i) /min(suit_count);
                    end
                    disp(card_viability);
                    %%%Leading-specific viability    
                    if leading_suit == 0
                        % Viability of high cards
                        disp('compute high cards')
                        disp(high_cards)
                        for i = 1:4
                            card_viability = card_viability + (suit == i & nums == high_cards(i)) * 1.2; 
                        end
                        disp(card_viability);
                    else
                    %%%Following-specific viability
                        disp('Leading high card')
                        played_cardvalues = [round.cards_played.value];
                        played_cardsuits = floor(played_cardvalues/100);
                        trumped = any(played_cardsuits == tb.trump_suit) && leading_suit ~= tb.trump_suit;
                        %current_high_card = round.cards_played.value(
                        
                        if trumped
                            card_viability = card_viability - (suit~=tb.trump_suit).*nums/7;
                        end
                        % Favour highest number of leading suit available in game , when following suit
                        card_viability = card_viability + (suit == leading_suit & nums == high_cards(leading_suit)) * 1.2;
                        disp(card_viability);
                        disp('Trumping card')
                        % Favour low cards if cannot go higher
                        card_viability = card_viability + (nums<max(played_cardvalues))./nums;
                        % Favour trumps, low number, when out of leading suit
                        max_trump_played = max(played_cardvalues(played_cardsuits == tb.trump_suit));
                        if isempty(max_trump_played)
                            max_trump_played=1;
                        end
                        disp('max Trump card number:')
                        disp(max_trump_played);
                        card_viability = card_viability + (suit==tb.trump_suit & nums>max_trump_played )./nums *2;
                        disp(card_viability);
                    end
                    %%%Partner-specific viability
                    if player.partner
                    end
                    
                    % Step 3: Pick the most favourable card, random if more
                    % than one
                    best_cards = playable_cards(card_viability == max(card_viability));
                    action = player.hand(best_cards(randi(length(best_cards)))== [player.hand.value]);
                    %action = Vibot1.randomPlay(player,tb,leading_suit);
                otherwise
                    disp('State of game is undefined')
            end
        end
        
        function updateBelief(player,tb,game)
            narginchk(2,3);
            %update belief of partner
            if player.partner==0
                if sum(player.belief_partner)==0                                %this player don't know anything yet
                    switch player.role
                        case 'Declarer'
                            player.belief_partner(tb.declarer)=1;
                            player.belief_partner=~player.belief_partner;
                        case 'Partner'
                            player.belief_partner(tb.declarer)=1;
                        case 'Defender'
                            player.belief_partner(tb.declarer)=1;
                            player.belief_partner(player.num)=1;
                            player.belief_partner=~player.belief_partner;
                        otherwise
                            input('How come you dont know your role yet?')
                    end
                end
                player.belief_partner=player.belief_partner/sum(player.belief_partner); % normalise
            end
            
            %update belief of card distribution
            if tb.state==1 && sum(player.belief_carddist)==0
                suit = floor([player.hand.value]/100);
                num = mod([player.hand.value],100)-1;
                player.belief_carddist=ones(4,13,4)/3;
                for n=1:13
                    player.belief_carddist(:,num(n),suit(n))=0;
                    player.belief_carddist(player.num,num(n),suit(n))=1;
                end
            else
                suit=floor(game.cards_played(game.turn)/100);
                num=mod(game.cards_played(game.turn),100)-1;
                player.belief_carddist(:,num(n),suit(n))=0;
                % has some players been void of a suit
                if game.cards_played(game.turn)~=game.leading_suit
                    player.belief_carddist(game.players_turn,:,game.leading_suit)=0;
                end
                % normalising
                i=sum(player.belief_carddist);i(i==0)=1;
                player.belief_carddist=player.belief_carddist./i;
            end
        end
        
        function action = randomPlay(player,tb,leading_suit)
            disp('Play randomly')
            suit = floor([player.hand.value]/100);
            if leading_suit==0                                         %the player is the leader
                if tb.trump_broken==1 || isempty(player.hand(suit~=tb.trump_suit))
                    action= player.hand(randi(length(suit)));
                else
                    card_to_choose_from=player.hand(suit~=tb.trump_suit);
                    action=card_to_choose_from(randi(length(card_to_choose_from)));
                end
            elseif any(suit==leading_suit)                             %if there are suit equal to leading suit in hand (follow suit)
                card_to_choose_from=player.hand(suit==leading_suit);
                action=card_to_choose_from(randi(sum(suit==leading_suit)));
            else
                action= player.hand(randi(length(suit)));              % if no suit equal to leading suit in hand
            end
        end
        
    end
end

