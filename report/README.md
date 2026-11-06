# 技术报告

[阅读公开版 PDF](GKC3-Simulink-Technical-Report.pdf) · [LaTeX 源码](source/main.tex)

本报告以最新综合报告为基础，保留中英文摘要、技术章节 1–9、公式、数值结论、图表及参数附录。公开版采用中性 CTEX 封面，移除成员真实姓名、机构与教师信息、私人仓库链接；协作章节和复现附录改为当前公开仓库的说明。重新排版后页数可能与原 33 页版本不同。

## 编译

需要包含中文 CTEX、XeLaTeX、biber、gb7714-2015、TikZ、circuitikz 等包的 TeX Live 环境。使用 TeX Live 的 Fandol 字体，不依赖个人电脑安装的字体。

```bash
cd report/source
latexmk -xelatex -interaction=nonstopmode -halt-on-error main.tex
```

生成 `main.pdf`。仓库中的阅读版使用文件名 `GKC3-Simulink-Technical-Report.pdf`。

## 对照结果的范围

报告保留历史母线六工况、ODE 基准及另一套晶闸管整流接口的分析。这些历史实现未全部纳入当前公开快照；它们属于报告记录的对照证据，不等于当前仓库包含相应全部复现代码。当前可独立运行的模型与脚本见复现附录和仓库 README。

第三方公开出版物的作者署名保留。内部指导材料的作者和机构在公开版引用中隐去，原件不分发。
