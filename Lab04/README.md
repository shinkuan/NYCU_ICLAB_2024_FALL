# Lab04

這邊我覺得有幾個值得一提的優化方式。

在Activation Function的部分，要完成Sigmoid和Tanh，講義上提供的公式為：

$\sigma(x) = \frac{1}{1 + e^{-x}}$

$\tanh(x) = \frac{e^x - e^{-x}}{e^x + e^{-x}}$

這邊可以tanh上下同除$e^{x}$，這樣就可以省下一個exp的運算電路。

$\tanh(x) = \frac{1 - e^{-2x}}{1 + e^{-2x}}$

另外仔細閱讀Spec，可以發現0.005的誤差以內是可以接受的。

雖然助教規定了`inst_sig_width`、`inst_exp_width`等數值不可以改變，但完全可以自己做一個FP運算的module，因此我決定自己寫一個低精度FP運算的module，這樣可以省下很多面積。

我額外產了數百萬個測資來測試，確保誤差在0.005以內。
