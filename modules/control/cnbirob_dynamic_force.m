function [force, potential, support] = cnbirob_dynamic_force(width, height, interval, resolution)

    if nargin < 3
        interval = [0 1];
        resolution = 0.01;
    elseif nargin < 4
        resolution = 0.01;
    end

    if ( diff(interval) < 0 || length(diff(interval)) ~= 1 )
        error('chk:arg', 'interval must be a 2-length interval vector: [lower upper]');
    end
    
    x = interval(1):resolution:interval(2);
    
    if isscalar(width) == false
        error('chk:arg', 'width must be a scalar');
    end
    
    if isscalar(height) == false
        error('chk:arg', 'height must be a scalar');
    end
    
    if( width < interval(1) || width > interval(2) )
        error('chk:arg', 'values of width must be inside the provide interval');
    end

    force = nan(length(x), 1);

    
    for xId = 1:length(x)
        cx = x(xId);
        
        if(cx >= 0 && cx < (0.5 - width))
            cy = -sin( (pi./(0.5 - width) ) .*cx);
        elseif(cx >= (0.5 - width) && cx <= (0.5 + width))
            cy = -height.*sin(pi.*(cx - 0.5)./width);
        elseif (cx > (0.5 + width) && cx <= 1)
            cy = sin( (pi./(0.5-width)).*(cx-0.5- width));
        end
        
        force(xId) = cy;
    end
    
    potential = -cumsum(force);
    support = x;

end