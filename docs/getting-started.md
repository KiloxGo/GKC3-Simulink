# 运行与复现

## 环境

- 已验证：MATLAB R2026a、Simulink、Simscape、Simscape Electrical。
- 整机使用 accelerator 模式；请配置该 MATLAB 版本支持的 C/C++ 编译器。
- 旧任务使用 Specialized Power Systems；公开模型使用 Simscape Electrical。两者的库与求解器设置不能直接混用。
- 无需 MATLAB 即可阅读报告、PNG、PDF 和 CSV。

## 从仓库根目录开始

```matlab
addpath('Project')
start_project
run_integrated('startup')
export_integrated_materials('startup')
```

`start_project` 配置模型与组件路径、隔离缓存、初始化独立 CS 模型，并打开工作模型。缺少生成库时会从 `Components/+gkc/BidirectionalACDC.ssc` 构建。

完整运行：

```matlab
run_integrated('full')
export_integrated_materials('full')
```

输出 MAT 保存到 `Project/Results/raw/integrated`，导出的 CSV/PNG/PDF/FIG 保存到 `Project/Materials/Integrated`。原始 MAT 和缓存不进入 Git。

## 独立实验

```matlab
verify_hbridge_deadtime       % 0.42 s 全工况门极检查与图件
run_baselines                % 四个独立基线，包括 460 s CS 工况
export_writing_materials     % 从上述基线 MAT 导出图表
run_pwm_study                % 两个额外 PWM / 死区设置
export_pwm_study             % 需要先生成基线与对比 MAT
export_integrated_views      % 整机各层级模型截图
```

## 常见问题

| 现象 | 处理 |
| --- | --- |
| 找不到组件或模型 | 从仓库根目录运行 `start_project`，不要只打开单个 SLX |
| 组件版本或生成库不兼容 | 运行 `build_components`，再重新加载模型 |
| accelerator 编译失败 | 核对编译器和产品安装，先查看原始诊断；不要直接改变求解步长 |
| 导出脚本提示 MAT 不存在 | 先运行对应仿真；Git 中只提供已经导出的材料 |
| 与保存结果有细微差别 | 记录 MATLAB 版本、求解器、步长和组件源码后再比较 |

完整运行会花费数分钟至更久。首次构建通常比已有缓存更慢。其他 MATLAB 版本不在当前验证范围内。
