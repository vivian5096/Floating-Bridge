function [ bid] = calculate( cards_value,a,b )
% a=0.15,b=0.0017
            cards_suits = floor(cards_value/100);
            cards_num = mod(cards_value,100);
            X = zeros(1,4); %X is the number of cards in each suit
            for n=1:4
                X(n)=sum(cards_suits==n);
            end
            for trump=1:5
                bid(trump)=0;
                for n=1:4
                    if n==trump
                        points=sum(cards_num(cards_suits==n)==11)*1+...
                    sum(cards_num(cards_suits==n)==12)*2+...
                    sum(cards_num(cards_suits==n)==13)*3+...
                    sum(cards_num(cards_suits==n)==14)*4+...
                    sum(cards_num(cards_suits==n))*0.001;
                        bid(trump)=bid(trump)+points*X(n)*a;
                    else
                        points=sum(cards_num(cards_suits==n)==11)*calpoints(4,X(n))+...
                    sum(cards_num(cards_suits==n)==12)*calpoints(3,X(n))+...
                    sum(cards_num(cards_suits==n)==13)*calpoints(2,X(n))+...
                    sum(cards_num(cards_suits==n)==14)*calpoints(1,X(n))+...
                    sum(cards_num(cards_suits==n))*0.001;
                       bid(trump)=bid(trump)+points*log(X(n)+1)*b;
                    end
                end
            end
end
function [Y]=calpoints(jqka,X)
    if X==0
        Y=0;
    else
        if jqka <= X
            Y=exp(X-1)-1;
        else
            Y=19.167/X;
        end
    end
end
