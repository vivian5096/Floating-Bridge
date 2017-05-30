% things to add : break trump & check whether partner card
% is valid (for human input
function seed=Singbridge()
clc
close all
% Get information about the screen
scrsz = get(0,'ScreenSize');
win_ratio = scrsz(3:4)/scrsz(3);
win_size = scrsz(3:4)*0.8;

%set background colour, text colour and font size
background_colour=[0 0.2 0];
text_colour=[1 0.713725 0.756863];
role_text_colour=[0.12549 0.698039 0.666667];
font_size=0.6;
see_all_deck=1; % 0 to see all 1 to play normally

% Construct the window
win = figure('ToolBar','none','Name','Floating Bridge',...
    'NumberTitle','off','MenuBar','none',...
    'Resize','off','Visible','off','Color',background_colour,...
    'Position',[scrsz(3:4)-win_size*1.05 win_size]);
win.UserData=struct('game_delay',0.5);
win.UserData.background_colour=background_colour;

%initialise all cards
all_cards = Table.init_Cards();
suit_name={'Clubs','Diamonds','Hearts','Spades','No Trump'};
num_name={'2','3','4','5','6','7','8','9','10','J','Q','K','A'};

% Prepare playfield and drawing axes
[player_hand_deck,player_played_card,playfield_size] = prepare_playfield(all_cards,win_ratio,see_all_deck);
disp_axes = axes('Parent',win,'Position',[0 0 1 1]);
set(disp_axes,'Xlim',[0 playfield_size(1)],'Ylim',[0 playfield_size(2)],...
    'XLimMode','manual','YLimMode','manual','Visible','off','NextPlot','add');

%initialise players
%can choose 'Human' or 'randomAI' or 'Vibot1'
pl(1) = Player('Human',1,[]);
pl(2) = Player('Vibot1',2,[]);
pl(3) = Player('randomAI',3,[]);
pl(4) = Player('Vibot1',4,[]);

%draw textboxes to display player name, score,role and message
[player_text,score_text,role_text,message_text,choice_button,bidsuit_button,...
    bidnum_button,display_bidnum,display_bidsuit,bid_button,pass_button,...
    partner_button,call_button]=draw_Uicontrols(all_cards,pl,playfield_size,background_colour,...
    text_colour,role_text_colour,font_size);

draw_playfield(player_hand_deck,player_played_card)
set(win,'Visible','on')

%loop game
continue_game=1;
while continue_game==1
    seed=rng;
    try
        %reset graphics
        set(message_text,'fontsize',0.3);
        set(message_text,'string','');
        set(score_text,'string','');
        set(role_text,'string','');
        
        %initialise players, table scores & set the state of game to 0
        tb=Table(pl,0,[0 0 0 0]);
        
        % state 0: shuffling, dealing out cards & request for reshuffle
        no_times_dealt=0; request_reshuffle=[1;1;1;1];
        while sum(request_reshuffle)>0
            Decks = Table.shuffle(all_cards);%(all_cards,1) to manually allocate the cards % autoshuffle cards
            for n=1:4
                update_Hand(tb.players(n),Decks(n,:));                      % distribute cards
                append_Cards(player_hand_deck(n),Decks(n,:));               % update cardholder
                if strcmp(tb.players(n).type,'Human')
                    player_hand_deck(n).always_hidden=0;                    % only show human player's card
                end
                update_Deck_Graphics(player_hand_deck(n),disp_axes);        % update graphics
                determine_Point(tb.players(n));                             % all players determine points
            end
            for n=1:4
                request_reshuffle(n)=check_Points(tb.players(n),...         % ask fore reshuffle requests
                    message_text,choice_button,win);   
                set(message_text,'string','');                              % reset graphics
                set(choice_button(1),'visible','off');set(choice_button(2),'visible','off');
            end            
            if  sum(request_reshuffle)>0
                for n=1:4
                    clear_Deck(player_hand_deck(n),disp_axes);
                end
            end
            no_times_dealt=1+no_times_dealt;
            if no_times_dealt>3                                             % can only accept reshuffle request 3 times
                set(message_text,'string','Reshuffled 3 times. No longer accepting reshuffle request!'); pause(game_delay);
                break
            end
        end
        set(message_text,'string','');
        
        % State 1: Bidding Process
        tb.state=1;
        %first bidder is assigned randomly
        bidding_Process(tb,suit_name,score_text,message_text,win,bidsuit_button,...
            bidnum_button,display_bidnum,display_bidsuit,bid_button,pass_button,player_text);
        set(bidsuit_button,'visible','off');set(bidnum_button,'visible','off');
        set(bid_button,'visible','off');set(pass_button,'visible','off');
        set(display_bidnum,'visible','off');set(display_bidsuit,'visible','off');
        msg1=sprintf('Bid is %d and Trump suit is %s',floor(tb.bid/10), string(suit_name(tb.trump_suit)));
        set(message_text,'string',msg1);
        set(role_text(tb.declarer),'string','Declarer');
        non_declarer=find([1 2 3 4]~=tb.declarer);
        
        % State 2: Choose partner
        tb.state=2;
        call_Partner(tb,all_cards,win,message_text,...
            partner_button,call_button,bidsuit_button,display_bidnum,display_bidsuit);
        set(bidsuit_button(1:4),'visible','off');
        set(display_bidnum,'visible','off'); set(display_bidsuit,'visible','off');
        set(partner_button,'visible','off');set(call_button,'visible','off');
        set(display_bidnum,'string',''); set(display_bidsuit,'string','');
        msg2=strcat('Partner card is ',num_name(mod(tb.partner_card.value,100)-1),...
            ' ',suit_name(floor(tb.partner_card.value/100)));
        msg2=[msg1,msg2];
        set(message_text,'string',msg2);
        % non-bidder identify themselves
        for n=1:3
            identify_Role(tb.players(non_declarer(n)),tb.partner_card,tb.declarer);
        end
        
        % Start game
        tb.state=3;
        set(win,'ButtonDownFcn',@check_clicked_deck)
        % initialise 13 games
        for n=1:14
            game(n)=Game(n);
        end
        no_of_trick=1; %game counter
        game(no_of_trick).leader=first_Leader(tb);  % identify first leader       
        while no_of_trick<=13
            game(no_of_trick+1).leader=trick(tb,game(no_of_trick), message_text,role_text,...
                player_hand_deck,disp_axes,player_played_card,win,msg2,player_text);
            tb.scores(game(no_of_trick+1).leader)=tb.scores(game(no_of_trick+1).leader)+1;
            no_of_trick=no_of_trick+1;
            for n=1:4
                set(score_text(n),'string',num2str(tb.scores(n)));
            end
        end
        
        % declare winning team
        [winning_team, no_set_won_above_bid]=who_Win(tb);
        msg3=sprintf('Winning team is %s. No of set won above bid is %d \n',winning_team, no_set_won_above_bid);
        set(message_text,'fontsize',0.2)
        set(message_text,'string',[msg3,'Continue game?'])
        set(win,'ButtonDownFcn','')
    catch ME
        msg = getReport(ME); disp(msg);
        break
    end
    
    %ask player whether to continue game
    set(choice_button(1),'visible','on');set(choice_button(2),'visible','on');
    uiwait(win);
    continue_game=win.UserData.decision;
    %continue_game=input('Continue game? <1>Yes <else>No');
end
close all
%% GUI functions
% Prepare the playing field dimension with the card holders
    function [player_hand_deck,player_played_card,playfield_size] = prepare_playfield(cards,win_ratio,see_all_deck)
        card_size = size(cards(1).get_Card_Image('front'));
        card_width = card_size(2);
        card_height = card_size(1);
        card_gap=10;
        border_offset = 10;
        playfield_width = round(card_width*15+2*border_offset);
        playfield_size = round([playfield_width playfield_width].*win_ratio);
        
        % Compute the position and dimensions
        start_x = border_offset;
        start_y =border_offset;
        card_voffset = (playfield_size(2)-2*border_offset-3*card_height)/12;%card_width;(start_y-card_height-offset)/18;
        card_hoffset= (playfield_size(1)-2*border_offset-3*card_width)/12;
        % Initialise the card holders
        player_hand_deck(1)=cardHolder(start_x+card_width,start_y+card_height,...
            [],card_width,card_height,card_hoffset,'horizontal',-1,0,see_all_deck,0);
        player_hand_deck(2)=cardHolder(start_x,start_y+card_height*2+card_voffset*12,...
            [],card_width,card_height,card_voffset,'vertical',-1,0,see_all_deck,0);
        player_hand_deck(3)=cardHolder(start_x+card_width,start_y+card_height*3+card_voffset*12,...
            [],card_width,card_height,card_hoffset,'horizontal',-1,0,see_all_deck,0);
        player_hand_deck(4)=cardHolder(start_x+card_width*2+card_hoffset*12,start_y+card_height*2+card_voffset*12,...
            [],card_width,card_height,card_voffset,'vertical',-1,0,see_all_deck,0);
        
        player_played_card(1)=cardHolder(start_x+card_width*2+card_hoffset*5,start_y+card_height*2+card_gap,...
            [],card_width,card_height,card_hoffset,'horizontal',-1,0,0,0);
        player_played_card(2)=cardHolder(start_x+card_width+card_gap,start_y+card_height*2+card_voffset*7,...
            [],card_width,card_height,card_hoffset,'horizontal',-1,0,0,0);
        player_played_card(3)=cardHolder(start_x+card_width*2+card_hoffset*5,start_y+card_height*2+card_voffset*12-card_gap,...
            [],card_width,card_height,card_hoffset,'horizontal',-1,0,0,0);
        player_played_card(4)=cardHolder(start_x+card_width+card_hoffset*12-card_gap,start_y+card_height*2+card_voffset*7,...
            [],card_width,card_height,card_hoffset,'horizontal',-1,0,0,0);
        
        
    end
%function to draw the uicontrols
    function [player_text,score_text,role_text,message_text,choice_button,bidsuit_button,bidnum_button,...
            display_bidnum,display_bidsuit,bid_button,pass_button,partner_button,call_button]=draw_Uicontrols(...
        all_cards,pl,playfield_size,background_colour,text_colour,role_text_colour,font_size)
        %screensize = get(0,'ScreenSize');
        %[winwidth, winheight] = screensize(3:4)*0.8;
        card_size = size(all_cards(1).get_Card_Image('front'));
        card_width = card_size(2);
        card_height = card_size(1);
        card_voffset = (playfield_size(2)-2*10-3*card_height)/12;
        player_text(1)=uicontrol('style','text','string',pl(1).type,...
            'position',[card_width*5,55+card_height,card_width*1.2,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',text_colour,...
            'FontSize',font_size);
        player_text(2)=uicontrol('style','text','string',pl(2).type,...
            'position',[card_width+15,card_height*2+card_voffset*2-5,card_width*1.2,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',text_colour,...
            'FontSize',font_size);
        player_text(3)=uicontrol('style','text','string',pl(3).type,...
            'position',[card_width*5,card_height*2+10*card_voffset,card_width*1.2,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',text_colour,...
            'FontSize',font_size);
        player_text(4)=uicontrol('style','text','string',pl(4).type,...
            'position',[card_width*12+10,card_height*2+card_voffset*2-5,card_width*1.2,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',text_colour,...
            'FontSize',font_size);
        
        role_text(1)=uicontrol('style','text','string','',...
            'position',[card_width*5,20+card_height,card_width*1.2,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',role_text_colour,...
            'FontSize',font_size);
        role_text(2)=uicontrol('style','text','string','',...
            'position',[card_width+15,card_height*2+card_voffset*2-35,card_width*1.2,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',role_text_colour,...
            'FontSize',font_size);
        role_text(3)=uicontrol('style','text','string','',...
            'position',[card_width*5,card_height*2+10*card_voffset-35,card_width*1.2,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',role_text_colour,...
            'FontSize',font_size);
        role_text(4)=uicontrol('style','text','string','',...
            'position',[card_width*12+10,card_height*2+card_voffset*2-35,card_width*1.2,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',role_text_colour,...
            'FontSize',font_size);
        
        score_text(1)=uicontrol('style','text','string','',...
            'position',[card_width*8,20+card_height,card_width,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',text_colour,...
            'FontSize',font_size);
        score_text(2)=uicontrol('style','text','string','',...
            'position',[card_width+15,card_height*3+card_voffset*2+35,card_width,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',text_colour,...
            'FontSize',font_size);
        score_text(3)=uicontrol('style','text','string','',...
            'position',[card_width*8,card_height*2+10*card_voffset-35,card_width,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',text_colour,...
            'FontSize',font_size);
        score_text(4)=uicontrol('style','text','string','',...
            'position',[card_width*12+15,card_height*3+card_voffset*2+35,card_width,25],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',text_colour,...
            'FontSize',font_size);
        
        message_text=uicontrol('style','text','string','',...
            'position',[card_width*3+15,card_height*2+card_voffset*2-5,playfield_size(1)*0.5,playfield_size(2)*0.15],...
            'FontUnits','normalized','BackgroundColor',background_colour,'ForegroundColor',[1 1 1],...
            'FontSize',0.3);
        
        for j=1:7
            bidnum_button(j)=uicontrol('style','pushbutton','string',num2str(j),...
                'position',[card_width*2.5+card_width*0.5*(j-1),card_height*2+card_voffset*2-35,card_width*0.4,30],...
                'visible','off','callback',{@display_Bidnum,j});
        end
        
        for i=1:5
            bidsuit_button(i)=uicontrol('style','pushbutton','string',suit_name(i),...
                'position',[card_width*5.5*1.5+card_width*0.8*(i-1),card_height*2+card_voffset*2-35,card_width*0.7,30],...
                'visible','off','callback',{@display_Bidsuit,suit_name(i)});
        end
        
        for k=1:13
            partner_button(k)=uicontrol('style','pushbutton','string',num_name(k),...
                'position',[card_width*2.5+card_width*0.5*(mod(k-1,7)),...
                card_height*2+card_voffset*(2-floor((k-1)/7)*1.2)-35,card_width*0.4,30],...
                'visible','off','callback',{@display_Partner_Cardnum,k});
        end
        
        call_button=uicontrol('style','pushbutton','string','CALL',...
            'position',[card_width*(5.5*1.5+0.8),card_height*1.5,card_width*0.7,30],...
            'visible','off','callback',@partner_Called);
        
        pass_button=uicontrol('style','pushbutton','string','PASS',...
            'position',[card_width*(5.5*1.5+1.6),card_height*1.5,card_width*0.7,30],...
            'visible','off','callback',@bid_Passed);
        
        bid_button=uicontrol('style','pushbutton','string','BID',...
            'position',[card_width*(5.5*1.5+0.8),card_height*1.5,card_width*0.7,30],...
            'visible','off','callback',@bid_Entered);
        
        display_bidnum=uicontrol('style','text','string','',...
            'position',[card_width*4*1.6,card_height*2+card_voffset*2-35,card_width*0.4,30],...
            'visible','off','FontUnits','normalized','BackgroundColor',[0 0 0],'ForegroundColor',[1 1 1],...
            'FontSize',font_size);
        
        display_bidsuit=uicontrol('style','text','string','',...
            'position',[card_width*(4*1.6+0.4),card_height*2+card_voffset*2-35,card_width,30],...
            'visible','off','FontUnits','normalized','BackgroundColor',[0 0 0],'ForegroundColor',[1 1 1],...
            'FontSize',font_size);
        
        choice_button(1)=uicontrol('style','pushbutton','string','Yes',...
            'position',[card_width*5,card_height*2+card_voffset*2-5,card_width*0.7,30],...
            'visible','off','callback',{@choice,1});
        choice_button(2)=uicontrol('style','pushbutton','string','No',...
            'position',[card_width*8,card_height*2+card_voffset*2-5,card_width*0.7,30],...
            'visible','off','callback',{@choice,0});
    end

% Draw the play field
    function draw_playfield(player_hand_deck,player_played_card)
        cla(disp_axes);     % Clear the play field axes, not that it is needed since it is only called during initialisation
        for i = 1:length(player_hand_deck)
            %player_hand_deck(i).render_deck_outline(disp_axes);
            player_hand_deck(i).update_Deck_Graphics(disp_axes);
        end
        
        for i = 1:length(player_played_card)
            player_played_card(i).render_deck_outline(disp_axes);
            player_played_card(i).update_Deck_Graphics(disp_axes);
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
        set(display_bidnum,'string',num2str(val))
    end
% Callback function of bidsuit buttons
    function display_Bidsuit(~,~,val)
        set(display_bidsuit,'string',val)
    end
%Callback function of pass button
    function bid_Passed(~,~)
        win.UserData.humanbidresult=0;
        uiresume(win);
    end
% Callback function of bid button
    function bid_Entered(~,~)
        bidnum=get(display_bidnum,'string');
        bidsuit=get(display_bidsuit,'string');
        if isempty(bidnum) || isempty(bidsuit)
            return
        end
        b=find(strcmp(suit_name,bidsuit));
        win.UserData.humanbidresult=str2double(bidnum)*10+b;
        uiresume(win);
    end
%callback function of partner buttons
    function display_Partner_Cardnum(~,~,k)
        set(display_bidnum,'string',num_name(k));
    end
%callback function of call button
    function partner_Called(~,~)
        partnernum=get(display_bidnum,'string');
        partnersuit=get(display_bidsuit,'string');
        if isempty(partnernum) || isempty(partnersuit)
            return
        end
        a=find(strcmp(num_name,partnernum))+1;
        b=find(strcmp(suit_name,partnersuit));
        win.UserData.callpartner=b*100+a;
        uiresume(win);
    end
%button down callback function of window
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