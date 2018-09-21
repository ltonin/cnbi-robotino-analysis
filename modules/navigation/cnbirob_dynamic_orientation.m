clearvars; clc;

x = 0:.01:0.6;
y = -0.6:.01:0.6;
lambda_a = -1;
lambda_r = 1;
beta = 1;
dtheta = pi/5;
RobotRadius = 0.2;
[X, Y] = meshgrid(x, y);

[PHI, RHO] = cart2pol(X, Y); 
%PHI = PHI - pi/2;
SIGMA = atan(tan(dtheta/2) + RobotRadius./(RobotRadius + RHO));
Fa = lambda_a.*exp(-(RHO./beta)).*(PHI);
Fr = lambda_r.*exp(-(RHO./beta)).*(PHI).*exp(-((PHI.^2)./(2.*power(SIGMA, 2))));

subplot(1, 2, 1);
imagesc(x, y, rot90(Fr))
axis square;
%set(gca, 'YDir', 'normal')
title('Repellor');
colorbar('location', 'SouthOutside');


subplot(1, 2, 2);
imagesc(x, y, rot90(Fa));
axis square;
%set(gca, 'YDir', 'normal')
title('Attractor');
colorbar('location', 'SouthOutside');
