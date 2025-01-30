# Integrated Circuit Design Laboratory (ICLAB) 2024 Fall

## ICLAB

- 課程名稱：積體電路設計實驗 Integrated Circuit Design Laboratory 
- 開課學期：113-1
- 授課教師：李鎮宜副校長
- 開課單位：電子碩
- 修課人數：170人
- 退選人數：32人
- 退選人數 : 32
- 全班平均 : 81.27

---

## Lab Descriptions

- Process: U18
- Simulation: VCS
- Synthesis: Design Compiler
- APR: Innovus

|  Lab  | Topic                                | Name                                           |  W  |
|-------|--------------------------------------|------------------------------------------------|-----|
| Lab01 | Combinational Circuit                | Snack Shopping Calculator (SSC)                |  5% |
| Lab02 | Sequential Circuit                   | Three-Inning Baseball Game (BB)                |  5% |
| Lab03 | Pattern                              | Tetris (+Pattern)                              |  5% |
| Lab04 | Designware IP                        | Convolution Neural Network (CNN)               |  5% |
| Lab05 | Memory                               | Template Matching with Image Processing (TMIP) |  5% |
| Lab06 | Design Compiler & Soft IP            | Matrix Determinant Calculator (MDC)            |  5% |
| Lab07 | Cross Domain Clock                   | Convolution with Clock Domain Crossing (CONV)  |  5% |
| Lab08 | Low Power Design                     | Self-attention (SA)                            |  5% |
| Lab09 | SystemVerilog Design                 | Stock Trading Program                          |  5% |
| Lab10 | SystemVerilog Verification           | Verification: From Lab09                       |  5% |
| Lab11 | APR flow with Innovus                | APR I: From Lab05                              |  5% |
| Lab12 | IR Drop after APR                    | APR II: From Lab03                             |  5% |
| Bonus | Formal Verification                  | Formal Verification                            |  3% |
| OT    | Online Test                          | Ramen                                          |  5% |
| MP    | DRAM with AXI-4                      | Image Signal Processing (ISP)                  | 10% |
| FP    | APR with MP                          | Image Signal Processing (ISP)                  | 10% |
| ME    | Focus on front-end design            | Midterm Exam (written exam)                    |  8% |
| FE    | Focus on back-end design             | Final   Exam (written exam)                    |  8% |

參考[NYCU_ICLAB_2024_FALL](https://github.com/BoooC/NYCU_ICLAB_2024_FALL)

## Score

全部1st_demo通過，十分幸運。

分數跟那些霸榜的神人差多了，但還是希望能夠幫助到大家。

| Lab                                 | Rank   | Score | Pass Rate | 1de | 2de |
|-------------------------------------|--------|-------|-----------|-----|-----|
| [Lab01](./Lab01/)                   | 8      | 98.64 | 97.45%    | 154 |  0  |
| [Lab02](./Lab02/)                   | 55     | 89.48 | 92.36%    | 145 |  9  |
| [Lab03](./Lab03/)                   | 55     | 91.95 | 75.80%    | 119 | 26  |
| [Lab04](./Lab04/)                   | 16     | 96.81 | 75.80%    | 119 | 22  |
| [Lab05](./Lab05/)                   | 36     | 91.53 | 58.60%    |  93 | 31  |
| [Lab06](./Lab06/)                   | 70     | 85.52 | 81.53%    | 128 | 15  |
| [Lab07](./Lab07/)                   | 131    | 95.29 | 83.44%    | 133 |  7  |
| [Lab08](./Lab08/)                   | 123    | 74.04 | 85.99%    | 135 |  6  |
| [Lab09](./Lab09/)                   | 5      | 99.11 | 68.79%    | 108 | 27  |
| [Lab10](./Lab10/)                   | 30     | 97.87 | 80.89%    | 127 |  9  |
| [Lab11](./Lab11/)                   | 32     | 92.56 | 68.15%    | 107 | 27  |
| [Lab12](./Lab12/)                   | N/A    | 100.0 | 86.62%    | 136 |  0  |
| [Online Test](Online_Test)          | N/A    | 100.0 | 70.52%    | 122 | 21  |
| Midterm Project                     | 78     | 83.62 | 78.03%    | 135 |  6  |
| [Final Project](./Final_Project/)   | 10     | 97.99 | 76.30%    | 131 |  2  |
| **Total**                           | 24/138 | 96.84 | N/A       |  -  |  -  |

* Rank: 修課同學中的排名
* Total: 計算的分數除了以上的Lab、Online Test、Midterm Project、Final Project外，還包含了Bonus、Midterm Exam、Final Exam分數
* Pass Rate: 1st_demo通過率

## Content

資料夾內的檔案結構沒有按照原伺服器上的結構，且為避免侵權只保留了Design、Pattern、Exercise、Testbench等重要檔案。

每個Lab對應的資料夾內大致含有以下資料：
- *.pdf: Lab的題目
- Pattern: 
  - PATTERN.v: 除了Lab1、Lab2是TA給的，其他Lab的PATTERN.v都是我自己寫的。
  - PATTERN_TA.v, PATTERN.vp: 1de結束後，TA給的Pattern
  - PATTERN_???.v: 修課過程中，有神人造福同學寫的Pattern
- \<DesignName\>.v: Design的Verilog code
- txt: 通常是Testbench的測試資料
- README.md: 一些值得一提的東西