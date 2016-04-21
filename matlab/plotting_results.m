% Plotting deltas for comparison (indicative, not sole criterion for efficiency)
figure(1)
subplot(2,1,1)
plot(1:iter0,delta0);
title('Delta for value iteration');
subplot(2,1,2)
plot(1:iter1,delta1);
title('Delta for enhanced policy iteration');
figure(2)
subplot(3,1,1)
plot(1:iter,delta);
title('Delta for constrained policy iteration');
subplot(3,1,2)
plot(1:iter2,delta2);
title('Delta for synchronous speedy Q-learning');
subplot(3,1,3)
plot(2:iter3,delta3(2:end));
title('Delta for classic Q-learning');


print('-f1','deltas','-djpeg90');
print('-f2','deltas_the_sequel','-djpeg90');