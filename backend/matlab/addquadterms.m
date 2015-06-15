function [ G ] = addquadterms( F )
%[G]=addquadterms(F)
%   Takes F, assumes each column is a set of features
%   Adds rows, each new row = product of 2 original rows

D=size(F,1);
G=F;
    for i=1:D
        for j=i:D
            G=[G; G(i,:).*G(j,:)];
        end
    end

end

