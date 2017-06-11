classdef Human
    methods (Static)
        function bid=bet(current_bid,pl_bids,win)
            valid =0;
            while ~valid
                uiwait(win);
                bid=win.UserData.humanbidresult;%input('Bid? [<0> pass OR 1st no:no of set(s) to win; 2nd no: trump suit <1>clubs <2>diamonds <3>hearts <4>diamonds <5>No trump] ');
                check=dec2base(bid,10) - '0';
                if (bid == 0 || length(check)==2 && check(1)<=7 && check(2) <=5 && bid>current_bid)
                    valid=1;
                else
                    disp('Input is not valid');
                end
            end
        end
        
        function card_selected= partner(pl,all_cards,win,message_text)
            valid =0;
            while ~valid
                uiwait(win);
                card_value_selected=win.UserData.callpartner;
                if sum([pl.hand.value]==card_value_selected)>0
                    set(message_text,'string','Dont choose yourself!');
                else
                    valid=1;
                end
            end
            card_selected=all_cards([all_cards.value]==card_value_selected);
        end
        
        function card_played=select_Card(pl, leading_suit,tb,player_hand_deck)
            win = tb.win_handle;
            all_suit = floor([pl.hand.value]/100);
            valid =0;
            while ~valid
                uiwait(win);
                if player_hand_deck.check_Deck_Collision(win.UserData.Xx,win.UserData.Yy,'full')
                    card_ind = check_selection(player_hand_deck,win.UserData.Xx,win.UserData.Yy);
                    card_selected=pl.hand(card_ind).value;
                    suit = floor(card_selected/100);
                    
                    if leading_suit == 0
                        if suit == tb.trump_suit && tb.trump_broken==0 && any(floor([pl.hand.value]/100) ~= tb.trump_suit)
                            disp('Trump not broken');
                        else
                            valid=1;
                        end
                    else
                        valid = (suit==leading_suit || ~any(all_suit==leading_suit));
                        if ~valid
                            disp('Input is not valid');
                        end
                    end
                end
            end
            card_played=pl.hand([pl.hand.value]==card_selected);
        end
    end
end