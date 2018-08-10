function cnbirob_draw_field(coords, radius, field, varargin)
% cnbirob_draw_field(coords, radius, field, varargin)
%
% cnbirob_draw_field draws the experimental field by adding to the current
% image a circle for each target position provided (at position provided by
% coords and with the provided radius). In addition the function needs the
% field size. Optional arguments are the pair 'style', {style} (see viscircles)
% and 'flipped', true (to invert y-axis to plot on imagesc). 


    p = inputParser;
    
    validcoords  = @(x) isnumeric(x) && ismatrix(x) && size(x, 2) == 2;
    validradius  = @(x) isnumeric(x) && isscalar(x);
    validfield   = @(x) isnumeric(x) && isvector(x) && length(x) == 2;

    addRequired(p, 'coords', validcoords);
    addRequired(p, 'radius', validradius);
    addRequired(p, 'field',  validfield);
    addParameter(p, 'style', {'Color', 'k', 'LineStyle', '-', 'LineWidth', 2});
    addParameter(p, 'flipped', false, @islogical);
    parse(p, coords, radius, field, varargin{:});

    style   = p.Results.style;
    flipped = p.Results.flipped;
    
    if flipped
        coords(:, 2) = abs(coords(:, 2) - field(2));
    end
    
    hold on;
    for i = 1:length(coords)
        viscircles(gca, coords(i, :), radius, style{:});
    end
    hold off;
    
end