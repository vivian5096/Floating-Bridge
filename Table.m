classdef Table <handle
    properties (SetAccess=public)
        state       % 0-dealing cards 1-bidding phase 2-choose partner 3-main game
        scores      % score board
    end
    properties (SetAccess=private)
        players     
        bid         % current bid        
        trump_broken
        % Constant
        trump_suit  % doubles
        partner_card
        declarer_win_set
        defender_win_set
        % Players' role
        declarer
        declarer_partner    % To be updated when partner card is revealed
        defenders
        win_handle          % The handle of the window which the game is on
    end
    
    methods
        % Initialisation
        function tb=Table(players,state,scores,win)
            tb.players=players;
            tb.state=state;
            tb.bid=0;
            tb.scores=scores;
            tb.trump_suit=0;
            tb.partner_card=Cards(1,1,1);
            tb.declarer_win_set=0;
            tb.defender_win_set=0;
            tb.trump_broken=0;
            tb.win_handle = win;
        end
        
        function bidding_Process(tb,suit_name,score_text,message_text,bidsuit_button,...
                bidnum_button,display_bidnum,display_bidsuit,bid_button,pass_button,player_text)
            
            win = tb.win_handle;
            set(message_text,'string','Start bidding');
            pause(win.UserData.game_delay);
            first_bidder=randi(4);
            counter=first_bidder; no_of_pass=0; tb.bid=0; pl_bids=zeros(7,4);
            %options=cumsum(ones(5,7))+ cumsum(ones(7,5)*10)';
            %options=reshape(options,[1,size(options,1)*size(options,2)]);
            while no_of_pass<3
                i=mod(counter,4);
                if i==0
                    i=4;
                end
                j=ceil(counter/4);
                set(player_text(i),'BackgroundColor',[0,0,0.25])
                pl_bids(j,i)=tb.players(i).place_Bid(tb.bid,pl_bids,win,...
                    bidsuit_button,bidnum_button,display_bidnum,display_bidsuit,bid_button,pass_button);
                if pl_bids(j,i)==0
                    bid_name='pass';
                else
                    suitind=mod(pl_bids(j,i),5);
                    if suitind==0
                        suitind=5;
                    end
                    bid_name=strcat(num2str(floor(pl_bids(j,i)/10)),suit_name(suitind));
                end
                set(score_text(i),'string',bid_name); pause(win.UserData.game_delay);
                if pl_bids(j,i)==0
                    no_of_pass=no_of_pass+1;
                else
                    no_of_pass=0; tb.bid=pl_bids(j,i);
                    set(message_text,'string',bid_name);
                    %options=options(find(options==tb.bid):end);
                end
                counter=counter+1;
                set(player_text(i),'BackgroundColor',win.UserData.background_colour);
            end
            [~,tb.declarer]=find(pl_bids==tb.bid);
            name_Declarer(tb.players(tb.declarer));                                    %update role of player who is declarer
            % update properties of table
            j =dec2base(tb.bid,10) - '0';
            tb.trump_suit=j(2);
            tb.declarer_win_set=6+j(1);
            tb.defender_win_set=14-tb.declarer_win_set;
        end
        
        function call_Partner(tb,all_cards,message_text,...
            partner_button,call_button,bidsuit_button,display_bidnum,display_bidsuit)
            
            tb.partner_card=tb.players(tb.declarer).choose_Partner(all_cards,tb,message_text,...
            partner_button,call_button,bidsuit_button,display_bidnum,display_bidsuit);
        end
        
        function leader=first_Leader(tb)
            j =dec2base(tb.bid,10) - '0';
            if j(2)==5
                leader=tb.declarer;
            else
                i=mod(tb.declarer+1,4); %person left of declarer
                if i==0
                    i=4;
                end
                leader=i;
            end
        end
        
        
        function next_leader=trick(tb,game,message_text,role_text,player_hand_deck,...
                disp_axes,player_played_card,msg2,player_text)
            win = tb.win_handle;
            counter=game.leader; game.turn=1;            
            set(message_text,'string',msg2);
            while counter<(game.leader+4)
                game.players_turn=mod(counter,4);
                if game.players_turn==0
                    game.players_turn=4;
                end
                set(player_text(game.players_turn),'BackgroundColor',[0,0,0.25])
                [game.cards_played(game.players_turn),selected_card_ind]=tb.players(game.players_turn).play_Card(game,tb,player_hand_deck(game.players_turn));                
                player_hand_deck(game.players_turn).selected_start_index=selected_card_ind;
                transfer_Selected_Cards(player_hand_deck(game.players_turn),player_played_card(game.players_turn));
                update_Deck_Graphics(player_hand_deck(game.players_turn),disp_axes);
                update_Deck_Graphics(player_played_card(game.players_turn),disp_axes); 
                pause(win.UserData.game_delay);
                
                % check if partner card is played.
                % if yes, update table & notify players
                if game.cards_played(game.players_turn).value==tb.partner_card.value                    
                    tb.declarer_partner=game.players_turn;
                    non_declarer=find([1 2 3 4]~=tb.declarer);
                    tb.defenders=find(non_declarer~=tb.declarer_partner);
                    non_declarerpartner=find([1 2 3 4]~=tb.declarer_partner);
                    for n=1:3
                        update_Players_Partners(tb.players(non_declarerpartner(n)),tb.declarer_partner, tb.defenders);
                        set(role_text(non_declarer(n)),'string',tb.players(non_declarer(n)).role);
                    end
                end
                % update leading suit played by first player
                if game.leading_suit==0
                    suit_played=floor(game.cards_played(game.players_turn).value/100);                    
                    game.leading_suit=suit_played;
                end
                counter=counter+1; game.turn=game.turn+1;
                set(player_text(game.players_turn),'BackgroundColor',win.UserData.background_colour);
            end
            %decide winner
            suit_played= floor([game.cards_played.value]/100);
            if any (suit_played == tb.trump_suit)
                a=find(suit_played == tb.trump_suit);
                trump_played=[];
                for i=1:length(a)
                    trump_played=[trump_played game.cards_played(a(i))];
                end
                next_leader=find([game.cards_played.value]==max([trump_played.value]));
                if tb.trump_broken~=1 && game.leading_suit ~= tb.trump_suit
                    tb.trump_broken=1;
                    set(message_text,'string','Trump broken!');
                end
            else
                b=find(suit_played == game.leading_suit);
                follow_suit_played=[];
                for i=1:length(b)
                    follow_suit_played=[follow_suit_played game.cards_played(b(i))];
                end
                next_leader=find([game.cards_played.value]==max([follow_suit_played.value]));
            end
            for n=1:4
                update_Memory(tb.players(n),game);
                clear_Deck(player_played_card(n),disp_axes);
            end
        end
        
        function [winning_team, no_set_won_above_bid]=who_Win(tb)
            declarer_team_score=tb.scores(tb.declarer)+tb.scores(strcmp({tb.players.role},'Partner'));
            defender_team_score=13-declarer_team_score;
            if declarer_team_score>=tb.declarer_win_set
                winning_team='Declarer';
                no_set_won_above_bid=declarer_team_score-tb.declarer_win_set;
            else
                winning_team='Defender';
                no_set_won_above_bid=defender_team_score-tb.defender_win_set;
            end            
        end
    end
    
    methods (Static)
        function all_cards = init_Cards()
            try
                crd = load('card_images.mat');
                card_images = crd.cards;
                card_backimage = crd.card_backimage;
                card_values = cumsum(ones(13,4))'+1+ cumsum(ones(4,13)*100);
                for i = 1:52
                    j = ceil(i/13);
                    k = mod(i-1,13)+1;
                    all_cards(i) = Cards(card_values(j,k),card_images{j,k},card_backimage);
                end
            catch
                disp('Load failed')
                close all
            end
        end
        
        function Decks = shuffle(all_cards,method)
            narginchk(1,2)
            if (nargin<2)
                method =0;
            end
            switch method
                case 1
                    valid=0;
                    while valid==0
                        shuf=input('Input card distribution that you want. [1-52] in a row vector');
                        if size(shuf,2)==52 && size(shuf,1)==1
                            if sort(shuf)~=cumsum(ones(1,52))
                                valid=0;disp('Invalid input')
                            else
                                valid=1;
                            end
                        else
                            valid=0; disp('Invalid input')
                        end
                    end
                otherwise
                    shuf=randperm(52);
            end
            for a=1:4
                Decks(a,:)=all_cards(sort(shuf((1+(a-1)*13):a*13)));
            end
        end

        %
    end
end