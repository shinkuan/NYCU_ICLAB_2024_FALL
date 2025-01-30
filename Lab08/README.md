# Lab08

在電路裡面加入一堆無用的Register，並讓它們的值反覆跳動，提高功耗，之後再加入Gated OR，這樣就能夠達到題目要求了。沒有功耗可以省，那就多用點功耗吧。

面積暴增，功耗也增加，效能分數慘烈。

另外值得一提的是，Gated OR本身的推力有限，如果一個Gated OR要接很多個Register，在RTL Simulation的時候可能不會有問題，但是Gate Level Simulation的時候就會出現問題，變成Unknown，這個bug找了很久，最後才找到問題所在。