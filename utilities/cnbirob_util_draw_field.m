function cnbirob_util_draw_field(radius, color, coords)

    if nargin < 3
        coords(:, 1) = [150 150];
        coords(:, 2) = [238 362];
        coords(:, 3) = [450 450];
        coords(:, 4) = [662 362];
        coords(:, 5) = [750 150];
    end
    
    hold on;
    for i = 1:length(coords)
        viscircles(gca, coords(1:2, i)', radius, 'Color', color);
    end
    hold off;

end