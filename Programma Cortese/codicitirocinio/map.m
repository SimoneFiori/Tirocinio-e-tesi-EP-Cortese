function deg_hat = map(deg) %rads
if deg>=0
    deg = deg+pi/2;
    coeff = mod(fix(deg/(pi)),2);
    if coeff
        deg_hat = pi-mod(deg,pi);
    else
        deg_hat = mod(deg,pi);
    end
    deg_hat = deg_hat - pi/2;
else
    deg = deg-pi/2;
    coeff = mod(fix(deg/(pi)),2);
    if coeff
        deg_hat = -pi-rem(deg,pi);
    else
        deg_hat = rem(deg,pi);
    end
    deg_hat = deg_hat + pi/2;

end


