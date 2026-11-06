# 仿真证据与验证范围

## 已记录的整机运行

主要证据为 [full/metrics.json](../Project/Materials/Integrated/full/metrics.json)、配套 CSV 和 [运行摘要](../Project/Results/integrated_full.json)。同一次联合仿真连续运行至 30 s，观测值均有限。

| 指标 | 结果 |
| --- | ---: |
| 6–11 s 的 Ip 均值 | 9999.276226 A |
| 1.8–1.85 s 的 Ip 观测峰峰值 | 226.547202 A |
| 观测 Vdc 最小 / 最大值 | 2187.020046 / 2219.178794 V |
| AC/DC 瞬时功率差最大绝对值 | 9.3132e-10 W |
| AC/DC 净能量差 | 0 J（该记录精度下） |
| 12.3–30 s 交流侧有符号能量 | −559210.358289 J |

负交流输入能量表示净回馈。整流器无损是模型方程的性质，能量差接近零不能用于证明实际器件效率。

## 门极与求解核查

- 整机启动及 29.98–30 s 观察窗口：桥臂无重叠导通，完整换相死区 2 µs。
- 修正版 H 桥独立运行 0.42 s：全程无桥臂重叠导通；排除指令禁用区间和不完整区间后，所有完整换相间隔为 2 µs。
- 原基线和 PWM 研究变体保留原浮点时间判断，可能出现 2–3 µs 死区，不能用作精确 2 µs 的证据。
- 启动段比较 3 次与 6 次非线性迭代，最大线圈电流差约 1.45e-8 A。详见 [求解器比较](../Project/Results/integrated_solver_comparison.json)。

## 公开副本验证

公开版验证已完成：7 个模型编译通过；2 s 启动综合观测的时间轴和全部数值与原记录逐点一致，最大差值为 0；独立 CS 初始化函数的 30 个字段与原初始化逐项一致。12 个 MATLAB 脚本的 Code Analyzer 检查为 0 项问题。证据见 [模型验证](validation/public-model-validation.json)、[参数等价检查](validation/cs-parameter-equivalence.json)及 [代码分析](validation/matlab-code-analysis.json)。先前 30 s 运行的导出结果与公开副本的验证分开记录，避免将旧运行描述为本次重跑。

GitHub Actions 执行文件、链接、数据与发布隐私规则检查，不运行 MATLAB 仿真。MATLAB 验证由本地 R2026a 完成。

以上核查范围不等于完整装置验证或全部课程要求验收。控制接口差异与模型假设见[模型说明](model-assumptions.md)。
