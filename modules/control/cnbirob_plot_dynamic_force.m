clearvars; clc; close all;

figdir = 'figure/';
width = 0.2;
height = 0.8;

[Ffree, Pfree, x] = cnbirob_dynamic_force(width, height); 


%% Plot
fig = figure;
fig_set_position(fig, 'Top');

NumRows = 1;
NumCols = 2;

subplot(NumRows, NumCols, 1); 
hold on;
plot(x, Ffree);
hattr = plot([0 0.5 1], [0 0 0], 'sg', 'MarkerSize', 10);
hrepl = plot([0.5-width 0.5+width], [0 0], 'or', 'MarkerSize', 10);
hold off;
grid on;
plot_hline(0, 'k');
legend([hattr hrepl], 'attractors', 'repellers', 'Location', 'southeast');
xlabel('y');
ylabel('F_{free}');
title('Free Force'); 

subplot(NumRows, NumCols, 2); 
plot(x, Pfree);
grid on;
xlabel('y');
ylabel('U_{free}');
title('Free Potential'); 

%% Saving
filename = [figdir '/dynamic_forces.pdf'];
util_bdisp(['Saving figure in ' filename]);
fig_figure2pdf(fig, filename);