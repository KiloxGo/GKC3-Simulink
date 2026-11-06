# 数据字段与使用口径

## 数据层级

| 目录 / 文件 | 用途 |
| --- | --- |
| `Project/Materials/Integrated/full` | 同一次 30 s 联合运行 |
| `Project/Materials/Integrated/startup` | 独立 2 s 启动运行 |
| `Project/Materials/VerifiedHBridge` | 修正版 H 桥验证 |
| `Project/Materials/PWMStudy` | 三组 PWM / 时间分辨率比较 |
| `Project/Materials/Figures`、`Tables` | 独立模块基线结果 |
| `Project/Results/raw` | 运行脚本生成的原始 MAT，不随仓库分发 |

PNG 用于预览，PDF 用于排版，CSV 用于数值分析。可编辑 FIG 通过导出脚本重新生成；公开快照不携带原工作会话的 FIG/MAT 对象。

## 联合模型 joint 的列定义

| 列 | 信号 | 单位 |
| --- | --- | --- |
| 1–4 | Iref、Enable、Demag、mH | A、逻辑、逻辑、无量纲 |
| 5–8 | Vrpl、Vab、Ics、Vloop | V、V、A、V |
| 9–11 | Rp、Lp、Ip | Ω、H、A |
| 12–16 | Vdc、Idc、Pac、Pdc、Pbridge | V、A、W、W、W |
| 17–19 | Eac、Edc、Ebridge | J |

综合观测每 10 µs 保存，能量按模型内部 1 µs 步长累计。`overview_1ms.csv` 是全程概览，`window_*_native.csv` 保留局部 10 µs 数据，`gates_native_1us.csv` 用于门极分析。

`power_1ms_means.csv` 的功率来自能量积分在 1 ms 窗口上的差分。不要使用概览表的开关电压、电流重新相乘计算能量；该做法会引入采样混叠。

所有指标使用文件给定的单位和统计窗口。不同工况、不同时间分辨率的峰峰值和能量不能直接混用。
