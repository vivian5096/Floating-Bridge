function seed=Singbridge()
%% Initialisations
clc
close all

default_size = [1366 768];
win_ratio = default_size/default_size(1);
win_size = default_size*0.8;

% Set background colour, text colour and font size
background_colour=[0 0.2 0];
text_colour=[1 0.713725 0.756863];
role_text_colour=[0.12549 0.698039 0.666667];
font_size=0.6;
see_all_deck = 0;

% Construct the window
win = figure('ToolBar','none','Name','Floating Bridge',...
    'NumberTitle','off','MenuBar','none',...
    'Resize','off','Visible','off','Color',background_colour,...
    'Position',[default_size-win_size*1.05 win_size]);
win.UserData=struct('game_delay',0.5,'bidnum','','bidsuit','');
win.UserData.background_colour=background_colour;

% Initialise all cards
all_cards = Table.init_Cards();
suit_name={'Clubs','Diamonds','Hearts','Spades','No Trump'};
num_name={'2','3','4','5','6','7','8','9','10','J','Q','K','A'};

% Prepare playfield and drawing axes
disp_axes = axes('Parent',win,'Position',[0 0 1 1]);
[player_hand_deck,player_played_card,playfield_size,midfield_size] = ...
    prepare_playfield(all_cards,win_ratio,~see_all_deck);
set(disp_axes,'Xlim',[0 playfield_size(1)],'Ylim',[0 playfield_size(2)],...
    'XLimMode','manual','YLimMode','manual','Visible','off','NextPlot','add');

% Initialise players
% Can choose 'Human' or 'randomAI' or 'Vibot1'
pl(1) = Player('Human',1,[]);
pl(2) = Player('Vibot1',2,[]);
pl(3) = Player('randomAI',3,[]);
pl(4) = Player('Vibot1',4,[]);

% Draw textboxes to display player name, score,role and message
[all_texts,bidding_buttons,choice_button,display_bid]=...
    draw_Uicontrols(all_cards,pl,playfield_size,midfield_size,background_colour,...
    text_colour,role_text_colour,font_size,player_played_card);
draw_playfield(player_hand_deck,player_played_card)

% Get information about the screen
scrsz = get(0,'ScreenSize');
win_size = scrsz(3:4)*0.7;
set(win,'Position',[scrsz(3:4)-win_size*1.05 win_size],'Visible','on');

% Initialise Table and Games
tb=Table(pl,0,[0 0 0 0],win,bidding_buttons,all_texts,display_bid);
for n = 1:14
    game(n)=Game(n);
end

%% Game Loop
continue_game=1;
while continue_game==1
    seed=rng;
    try
        %Reset Table
        reset_Table(tb);

        % state 0: shuffling, dealing out cards & request for reshuffle
        no_times_dealt=0; request_reshuffle=[1;1;1;1];
        while any(request_reshuffle)
            Decks = Table.shuffle(all_cards);%(all_cards,1) to manually allocate the cards % autoshuffle cards
            no_times_dealt = no_times_dealt+1;
            for n=1:4
                update_Hand(tb.players(n),Decks(n,:));                                  % Distribute cards
                append_Cards(player_hand_deck(n),Decks(n,:));                           % Update cardholder
                player_hand_deck(n).always_hidden = ~strcmp(tb.players(n).type,'Human');% only show human player's card
                update_Deck_Graphics(player_hand_deck(n));                              % Update graphics
                determine_Point(tb.players(n));                                         % all players determine points
            end
            if no_times_dealt>3                                             % can only accept reshuffle request 3 times
                set(all_texts{4},'string','Reshuffled 3 times. No longer accepting reshuffle request!'); 
                pause(game_delay);
                break
            end
            for n=1:4
                request_reshuffle(n)=check_Points(tb.players(n),...         % ask for reshuffle requests
                    all_texts{4},choice_button,win);   
                set(all_texts{4},'string','');                              % reset graphics
                set(choice_button,'visible','off');
            end            
            if any(request_reshuffle)
                for n=1:4
                    clear_Deck(player_hand_deck(n));
                end
            end
        end
        set(all_texts{4},'string','');
        
        % State 1: Bidding Process
        tb.state=1;
        % First bidder is assigned randomly
        msg1 = bidding_Process(tb,suit_name);
        pause(1)
        
        % State 2: Choose partner
        tb.state=2;
        call_Partner(tb,all_cards);
        non_declarer=find([1 2 3 4]~=tb.declarer); 
        msg2 =['Partner card is ',num_name{mod(tb.partner_card.value,100)-1},...
            ' ',suit_name{floor(tb.partner_card.value/100)}];
        msg3 = {msg1,msg2};
        set(all_texts{4},'string',msg3);
        % Non-bidder identify themselves
        for n = non_declarer
            identify_Role(tb.players(n),tb.partner_card,tb.declarer);
        end
        pause(1)
        
        % State 3: Start game
        tb.state=3;
        set(win,'ButtonDownFcn',@check_clicked_deck)
        % Reset the 13 games
        for n = 1:14
            reset_Game(game(n));
        end
        no_of_trick = 1; % Game counter
        game(no_of_trick).leader = first_Leader(tb);  % Identify first leader
        while no_of_trick<=13
            winner = trick(tb,game(no_of_trick),player_hand_deck,player_played_card,msg3);
            game(no_of_trick+1).leader = winner;
            tb.scores(winner)=tb.scores(winner)+1;
            set(all_texts{2}(winner),'string',num2str(tb.scores(winner)));
            no_of_trick=no_of_trick+1;
        end
        
        % declare winning team
        [winning_team, no_set_won_above_bid]=who_Win(tb);
        msg3=sprintf('Winning team is %s. No of set won above bid is %d \n',winning_team, no_set_won_above_bid);
        set(all_texts{4},'string',{msg3,'Continue game?'},'fontsize',0.2)
        set(win,'ButtonDownFcn','')
    catch ME
        msg = getReport(ME); disp(msg);
        break
    end
    
    %ask player whether to continue game
    set(choice_button,'visible','on');
    uiwait(win);
    continue_game=win.UserData.decision;
end
close all
%% GUI functions
% Prepare the playing field dimension with the card holders
    function [player_hand_deck,player_played_card,playfield_size,midfield_size] = prepare_playfield(cards,win_ratio,see_all_deck)
        card_size = size(cards(1).get_Card_Image('front'));
        card_width = card_size(2);
        card_height = card_size(1);
        card_gap=10;
        border_offset = 10;
        playfield_width = round(card_width*15+2*border_offset);
        playfield_size = round([playfield_width playfield_width].*win_ratio);
        midfield_offset = [card_width card_height]+ border_offset+card_gap;
        midfield_size = [midfield_offset playfield_size-midfield_offset*2];
        
        % Compute the position and dimensions
        start_x = border_offset;
        start_y =border_offset;
        card_voffset = (playfield_size(2)-2*border_offset-3*card_height)/12;
        card_hoffset= (playfield_size(1)-2*border_offset-3*card_width)/12;
        
        % Initialise the card holders
        for i = 1:4
            player_hand_deck(i)=cardHolder(...
                start_x + card_width*(i~=2) + (card_width+card_hoffset*12)*(i==4),...
                start_y + card_height + (card_voffset*12+card_height*(1+mod(i,2)))*(i~=1),...
                [],card_width,card_height,card_hoffset*mod(i,2)+card_voffset*mod(i-1,2),...
                mod(i,2),-1,0,see_all_deck,0,disp_axes);
        
            player_played_card(i)=cardHolder(...
                midfield_size(1) + (midfield_size(3) - card_width)/2* (1-sin(pi/2*(i-1))),...
                midfield_size(2) + midfield_size(4)/2 * (1-cos(pi/2*(i-1)))...
                + card_height/2 * (1+cos(pi/2*(i-1))),...
                [],card_width,card_height,card_hoffset,'horizontal',-1,0,0,0,disp_axes);

        end
    end
%function to draw the uicontrols
    function [all_texts,bidding_buttons,choice_button,display_bid]=draw_Uicontrols(...
        all_cards,pl,playfield_size,midfield_size,background_colour,...
        text_colour,role_text_colour,font_size,player_played_card)
    
        card_size = size(all_cards(1).get_Card_Image('front'));
        card_width = card_size(2);
        card_height = card_size(1);
        
    % All components are normalised based on playfield size
    % Player, Score, Role Texts are positioned based on the played cardHolder
        text_dim = [card_width*1.5 card_height/3];
        for i = 1:4
            refx = player_played_card(i).x;
            refy = player_played_card(i).y-text_dim(2)*0.8;
            ui_pos = [refx+(card_width*1.2)*mod(i,2)-card_width*0.5*(i==4),...
                        refy+(text_dim(2)*3)*mod(i-1,2),text_dim];
            player_text(i)= uicontrol('style','text','Units','Normalized',...
                'string',pl(i).type,'position',ui_pos./[playfield_size playfield_size]);
            score_text(i)=uicontrol('style','text','Units','Normalized',...
            'position',(ui_pos-[0 text_dim(2) 0 0])./[playfield_size playfield_size]);
            role_text(i)=uicontrol('style','text','Units','Normalized',...
                'position',(ui_pos-[0 text_dim(2)*2 0 0])./[playfield_size playfield_size]);
            if i==2
                set([player_text(i) score_text(i) role_text(i)],'HorizontalAlignment','left')
            elseif i==4
                set([player_text(i) score_text(i) role_text(i)],'HorizontalAlignment','right')
            end
        end
        set([player_text score_text role_text],'FontUnits','normalized','BackgroundColor',...
            background_colour,'ForegroundColor',text_colour,'FontSize',0.5);
        
        message_size = [midfield_size(3)-2*(card_width*1.2) midfield_size(4)-2*(card_height*1.2)];
        ui_pos = [midfield_size(1:2)+(midfield_size(3:4)-message_size)/2  message_size];
        message_text=uicontrol('style','text','Units','Normalized',...
            'position',ui_pos./[playfield_size playfield_size],...
            'FontUnits','normalized','BackgroundColor',background_colour,...
            'ForegroundColor',[1 1 1],'FontSize',0.5);
       
        all_texts = {player_text,score_text,role_text,message_text};
        
        button_w = (midfield_size(3)-(card_width*1.2)*3)/2/7;
        button_h = button_w/2;
        ypos =  midfield_size(2)+card_height*1.2;
        for i=1:7
            ui_pos = [midfield_size(1)+card_width*1.2+button_w*(i-1) ypos button_w button_h];
            bidnum_button(i)=uicontrol('style','pushbutton','string',num2str(i),'Units','Normalized',...
                'position',ui_pos./[playfield_size playfield_size],'callback',{@display_Bidnum,i});
        end
        
        button_w = (midfield_size(3)-(card_width*1.2)*3)/2/5;
        for i=1:5
            ui_pos = [midfield_size(1)+(midfield_size(3)+card_width*1.2)/2+button_w*(i-1)+10 ypos button_w button_h];
            bidsuit_button(i)=uicontrol('style','pushbutton','string',suit_name(i),'Units','Normalized',...
                'position',ui_pos./[playfield_size playfield_size],'callback',{@display_Bidsuit,suit_name{i}});
        end
        
        button_w = (midfield_size(3)-(card_width*1.2)*3)/2/13;
        for i=1:13
            ui_pos = [midfield_size(1)+card_width*1.2+button_w*(i-1) ypos button_w button_h];
            partner_button(i)=uicontrol('style','pushbutton','string',num_name(i),'Units','Normalized',...
                'position',ui_pos./[playfield_size playfield_size],'callback',{@display_Partner_Cardnum,i});
        end
        
        button_w = card_width;
        ui_pos = [midfield_size(1)+midfield_size(3)*3/4 ypos-button_h*1.2 button_w button_h];
        call_button=uicontrol('style','pushbutton','string','CALL','Units','Normalized',...
            'position',ui_pos./[playfield_size playfield_size],'callback',@partner_Called);
        bid_button=uicontrol('style','pushbutton','string','BID','Units','Normalized',...
            'position',ui_pos./[playfield_size playfield_size],'callback',@bid_Entered);
        
        ui_pos = [midfield_size(1)+midfield_size(3)*3/4+button_w ypos-button_h*1.2 button_w button_h];
        pass_button=uicontrol('style','pushbutton','string','PASS','Units','Normalized',...
            'position',ui_pos./[playfield_size playfield_size],'callback',@bid_Passed);
        
        ui_pos = [midfield_size(1:2)+[(midfield_size(3)-card_width*1.2)/2-card_width*2.5 card_height/2] card_width*2.5 card_height/2];
        display_bid=uicontrol('style','text','string','','Units','Normalized',...
            'position',ui_pos./[playfield_size playfield_size],'FontUnits','normalized',...
            'BackgroundColor',[0 0 0],'ForegroundColor',[1 1 1],'FontSize',font_size);
        
        ypos = player_played_card(1).y *1.05;
        ui_pos = [midfield_size(1)+(midfield_size(3)-card_width*1.2)/2-button_w,ypos,button_w,button_h];
        choice_button(1)=uicontrol('style','pushbutton','string','Yes','Units','Normalized',...
            'position',ui_pos./[playfield_size playfield_size],'callback',{@choice,1});
        ui_pos = [midfield_size(1)+(midfield_size(3)+card_width*1.2)/2+10,ypos,button_w,button_h];
        choice_button(2)=uicontrol('style','pushbutton','string','No','Units','Normalized',...
            'position',ui_pos./[playfield_size playfield_size],'callback',{@choice,0});
        
        set([bidnum_button bidsuit_button partner_button],'visible','off')
        set([call_button bid_button pass_button display_bid choice_button], 'Visible','off');
        
        bidding_buttons = {bidsuit_button,bidnum_button,...
            bid_button,pass_button,partner_button,call_button};
    end

% Draw the play field
    function draw_playfield(player_hand_deck,player_played_card)
        cla(disp_axes);     % Clear the play field axes, not that it is needed since it is only called during initialisation
        for i = 1:length(player_hand_deck)
            player_hand_deck(i).update_Deck_Graphics();
        end
        
        for i = 1:length(player_played_card)
            player_played_card(i).render_deck_outline();
            player_played_card(i).update_Deck_Graphics();
        end
    end

%% Callback functions
% Callback function of choice buttons
    function choice(~,~,decision)
        win.UserData.decision = decision;
        uiresume(win)        
    end
% Callback function of bidnum buttons
    function display_Bidnum(~,~,val)
        win.UserData.bidnum = num2str(val);
        set(display_bid,'string',[num2str(val),' ',win.UserData.bidsuit])
    end
% Callback function of bidsuit buttons
    function display_Bidsuit(~,~,val)
        win.UserData.bidsuit = val;
        set(display_bid,'string',[win.UserData.bidnum,' ',val])
    end
% Callback function of pass button
    function bid_Passed(~,~)
        win.UserData.humanbidresult=0;
        uiresume(win);
    end
% Callback function of bid button
    function bid_Entered(~,~)
        bidnum= str2double(win.UserData.bidnum);
        bidsuit= win.UserData.bidsuit;
        if isempty(bidnum) || isempty(bidsuit)
            return
        end
        b=find(strcmp(suit_name,bidsuit));
        win.UserData.humanbidresult= bidnum*10+b;
        uiresume(win);
    end
% Callback function of partner buttons
    function display_Partner_Cardnum(~,~,k)
        win.UserData.bidnum = num_name{k};
        set(display_bid,'string',[num_name{k},' ',win.UserData.bidsuit]);
    end
% Callback function of call button
    function partner_Called(~,~)
        partnernum= win.UserData.bidnum;
        partnersuit= win.UserData.bidsuit;
        if isempty(partnernum) || isempty(partnersuit)
            return
        end
        a=find(strcmp(num_name,partnernum))+1;
        b=find(strcmp(suit_name,partnersuit));
        win.UserData.callpartner=b*100+a;
        uiresume(win);
    end
% Button down callback function of window
    function check_clicked_deck(~,~)
        % Only allow left clicks, subject to changes
        if ~strcmp(get(win,'selectiontype'),{'normal','open'})
            return
        end
        mpos = get(disp_axes,'CurrentPoint');
        win.UserData.Xx=mpos(1,1);
        win.UserData.Yy=mpos(1,2);
        uiresume(win);
    end
end