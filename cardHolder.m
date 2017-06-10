%   Original author: En Yi
%   The card container class used in the solitaire game
%   Not optimised though
%   Anyone can modify it, just need to give credits to the original author
classdef cardHolder < handle
    %% Deck Properties
    properties (SetAccess = private)
        %Deck position 
        x                                                                   % x position of the top left of the holder
        y                                                                   % y position of the top left of the holder
        % Card dimension and offset 
        card_width
        card_height
        offset                                                              % The offset between display each card in a deck
        cards                                                               % The cards is currently holding
        % Card deck orientation and dimensions
        deck_orientation                                                    % Either display horizontal or vertical
        start_display_index                                                 % Display only a number of cards in a deck, -1 for display all
        current_display_index                                               % Current number of cards to be displayed
        % Overall deck dimension, used for collision purposes
        deck_width
        deck_height
        % Deck properties        
        receivable 
        % Deck graphics handle, used for updating the deck's graphics
        card_graphics_data = {}
        card_draw_handle = []
        card_text = []
    end
    properties (SetAccess = public)
        always_hidden                                                     % Never open the hidden cards
        selected_start_index                                                % The card index which is selected
        hidden_start_index                                                  % The number of cards that is hidden
    end
    methods
        %% Constructor
        function cH = cardHolder(x,y,cards,card_width,card_height,offset,deck_orientation,start_display_index,hidden_cards,always_hidden,receivable)
            cH.x = x;
            cH.y = y;
            
            % Check if a string is input,
            if isstring(deck_orientation)
                cH.deck_orientation = deck_orientation;
            else
                %Check for number input
                if deck_orientation == 1
                    cH.deck_orientation = 'horizontal';
                elseif deck_orientation == 0
                    cH.deck_orientation = 'vertical';
                end
            end
            
            if start_display_index<1
                start_display_index = -1;
            end
            cH.start_display_index = start_display_index;
            cH.current_display_index = start_display_index;
            
            cH.cards = cards;
            cH.card_width = card_width;
            cH.card_height = card_height;
            cH.offset = offset;
            
            cH.receivable = receivable ;
            cH.always_hidden = always_hidden;
            hidden_cards = min(hidden_cards,length(cards));
            cH.hidden_start_index = hidden_cards;
            
            cH.selected_start_index = 0;
            cH.update_deck_dimensions()
        end
        %% Deck Get Functions
        % Get the number of cards in the deck
        function n_of_cards = get_Number_Of_Cards(cH)
            n_of_cards = length(cH.cards);
        end
        function receive = is_Receivable(cH)
            receive = cH.receivable;
        end
        % Get the card at the bottom of the selected cards
        function card = get_bottom_selected(cH)
            card = cH.cards(end-cH.selected_start_index+1);
        end
        
        % Get the last card, which is top of the deck
        function lastcard = get_Last_Cards(cH)
            % If empty, return 0
            if cH.is_Empty()
                lastcard = 0;
                return
            end
            
            if (cH.get_Number_Of_Cards()-cH.hidden_start_index)>0
                lastcard = cH.cards(end);                                   % Return the card number if not hidden
            else
                lastcard = -1;                                              % If hidden, return -1;
            end
        end
        %% Deck Check Functions
        %Check if the deck is empty
        function empty = is_Empty(cH)
            empty = (cH.get_Number_Of_Cards() == 0);
        end
        
        %Check if there is a collision with a deck
        function collide = check_Deck_Collision(cH,x,y,type)
            
            if strcmp(type,'full') %Check for entire deck collision
                xrange = [cH.x cH.x+cH.deck_width];
                yrange = [cH.y-cH.deck_height cH.y];
            elseif strcmp(type,'first') %Check for only first card collision
                xoffset = cH.deck_width - cH.card_width;
                yoffset = cH.deck_height - cH.card_height;
                xrange = [cH.x+xoffset cH.x+cH.deck_width];
                yrange = [cH.y-cH.deck_height cH.y-yoffset];
            end
            
            collide = (x>xrange(1) && x<xrange(2)&& y>yrange(1) && y<yrange(2));
        end
        
        %Check the selected card index
        function sel_num = check_selection(cH,sel_x,sel_y)
            % If the deck is empty, don't proceed to calculations
            if cH.is_Empty()
                sel_num = 0;
                return
            end
            % Set up for the calculation depending on orientation
            if strcmp(cH.deck_orientation,'vertical')
                sel_point = sel_y;
                ref_point = cH.y;
                %first_card_range = cH.card_height;
            elseif strcmp(cH.deck_orientation,'horizontal')
                sel_point = sel_x;
                ref_point = cH.x;
                %first_card_range = cH.card_width;
            end
            % Check which card is selected
            relative_sel_point = abs(sel_point-ref_point);
            %if relative_sel_point<=first_card_range
            %    sel_num = 1;
            %else
            sel_num = min(cH.get_Number_Of_Cards(),...
                ceil(relative_sel_point/cH.offset));
            %end
            %sel_num = cH.get_Number_Of_Cards()- sel_num;
            % Check if the selected card is hidden
            if sel_num>cH.get_Number_Of_Cards()-cH.hidden_start_index
                sel_num = -1;
            end
        end
        %% Deck Modifying Functions
        % Add cards to the end, which is the top of the deck
        function append_Cards(cH,new_cards)
            cH.cards = [cH.cards new_cards];
            if cH.start_display_index>=0
                % Increase the current number of cards to display
                cH.current_display_index = cH.current_display_index+length(new_cards);
             % This is to limit how many cards can be display at a time,may make it conditional  
             cH.current_display_index = min(cH.current_display_index,cH.start_display_index);     
            end
            cH.update_deck_dimensions(); %Update the deck dimensions
        end
        
        % Remove the selected cards
        function remove_Selected_Cards(cH)
            cH.cards = [cH.cards(1:cH.selected_start_index-1) cH.cards(cH.selected_start_index+1:end)];
            
            if cH.current_display_index>0
                % Decrease the current number of cards to display
                cH.current_display_index = cH.current_display_index-cH.selected_start_index; 
                cH.current_display_index = max(cH.current_display_index,1);
            end
            %fprintf('Current display index: %d\n',cH.current_display_index)
            %cH.current_display_index = min(cH.current_display_index,cH.start_display_index);

            %cH.selected_start_index = 0;
            cH.update_deck_dimensions()
        end
        
         % Reveal a specified number of hidden cards from the top
        function reveal_Hidden_Card(cH,amount)
            cH.hidden_start_index = cH.hidden_start_index - amount;
        end
        
        % Transfer selected cards to another deck
        function transfer_Selected_Cards(cH,cH_to,varargin)
            selected_cards = cH.cards(cH.selected_start_index);
            if ~isempty(varargin)
                selected_cards = fliplr(selected_cards);
            end
            cH_to.append_Cards(selected_cards);
            cH.remove_Selected_Cards();
            cH.selected_start_index=0;
        end
        
        % Reset the number of cards to display
        function set_Current_Display(cH,num)
            if num<0
                cH.current_display_index = cH.start_display_index;
            else
                cH.current_display_index = max(num,1);
            end
            cH.update_deck_dimensions()
        end
        %% Deck Update/Reset Functions
        % Update the deck dimensions. MUST be called when cards are altered
        function update_deck_dimensions(cH)
            % Check how many are being display
            if cH.start_display_index>0
                cards_to_display = min(cH.current_display_index,cH.get_Number_Of_Cards());
            else
                cards_to_display = cH.get_Number_Of_Cards();
            end
            %If there is cards to display
            if cards_to_display>0
                 if strcmp(cH.deck_orientation,'vertical')
                    cH.deck_width = cH.card_width;
                    cH.deck_height = cH.card_height+cH.offset*(cards_to_display-1);
                elseif strcmp(cH.deck_orientation,'horizontal')
                    cH.deck_width = cH.card_width+cH.offset*(cards_to_display-1);
                    cH.deck_height = cH.card_height;
                 end
            else
                cH.deck_width = cH.card_width;
                cH.deck_height = cH.card_height;
            end
        end
        function update_Deck_Graphics(cH,disp_axes)
            cH.wipe_Deck_Graphics();
            cH.render_Deck(disp_axes);
        end
        
        % Clear the cards in the deck
        function clear_Deck(cH,disp_axes)
            cH.cards = [];
            cH.update_deck_dimensions();
            cH.update_Deck_Graphics(disp_axes);
        end
        %% Deck Console Functions
        % Display the cards on console
        function display_Cards(cH)
            disp(cH.cards)
        end
       
        %% Rendering functions        
        % Render the deck outline
        function render_deck_outline(cH,disp_axes)
            line(disp_axes,[cH.x cH.x+cH.card_width cH.x+cH.card_width cH.x cH.x],...
                 [cH.y cH.y cH.y-cH.card_height cH.y-cH.card_height cH.y],...
                 'PickablePart','none','Color',[1 1 1],'LineWidth',1)
        end
        
        % Render the cards in the deck
        function render_Deck(cH,disp_axes)
            % Draw shadow
%             if cH.get_Number_Of_Cards()>0
%                 deck_vertices(1,:) = [cH.x cH.x+cH.deck_width cH.x+cH.deck_width cH.x]+5;
%                 deck_vertices(2,:) = [cH.y cH.y cH.y-cH.deck_height cH.y-cH.deck_height]+5;
%                 cH.card_draw_handle(1) = patch(deck_vertices(1,:),deck_vertices(2,:),[1 0 0],'Parent',disp_axes,'PickableParts','none');
%             end
            if cH.current_display_index>0
                start_card = cH.get_Number_Of_Cards()-cH.current_display_index+1;
                start_card = max(start_card,1);
            else
                start_card = 1;
            end
            for i = start_card:cH.get_Number_Of_Cards()
                if strcmp(cH.deck_orientation,'vertical')
                    botleft_x = cH.x+0.5;
                    botright_y = cH.y-cH.card_height -cH.offset*(i-start_card)+0.5;

                elseif strcmp(cH.deck_orientation,'horizontal')
                    botleft_x = cH.x +cH.offset*(i-start_card)+0.5;
                    botright_y = cH.y-cH.card_height+0.5;
                end
                

                % The selection starts from the top of the stack
                if (i<=cH.hidden_start_index || cH.always_hidden)
                    %set(cH.card_draw_handle(i),'AlphaData',0.5);
                    img = cH.cards(i).get_Card_Image('back');
                else
                    img = cH.cards(i).get_Card_Image('front');
                end
                if i > length(cH.cards)- cH.selected_start_index
                    dark = ones(size(img))*0.2;
                    img = img - dark;
                end
                
                cH.card_draw_handle(i+1) = image(disp_axes,botleft_x,botright_y,...
                    img,'PickablePart','none');
%                 if i > length(cH.cards)- cH.selected_start_index
%                     set(cH.card_draw_handle(i),'AlphaData',0.5);
%                 end
                 
%                 cH.card_text(i) = text(disp_axes,text_pos(1),text_pos(2),num2str(cH.cards(i)),'PickableParts','none');
            end
        end
        
        % Delete the display cards in the deck, used for updating the deck
        function wipe_Deck_Graphics(cH)
            if ~isempty(cH.card_draw_handle)
                delete(cH.card_draw_handle)
                cH.card_draw_handle = [];
            end
            if ~isempty(cH.card_text)
                delete(cH.card_text)
                cH.card_text = [];
            end
        end
            
    end
end