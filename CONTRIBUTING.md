# Contributing

感谢参与 GKC3-Simulink。请先阅读[架构](docs/architecture.md)、[模型假设](docs/model-assumptions.md)和[数据口径](docs/data.md)。

## 建议流程

1. 在分支中修改，说明具体问题、模型层级及预期行为。
2. 参数变更注明来源，保留单位；新增建模假设写入文档。
3. 模型功能变更运行相关场景，并记录 MATLAB 版本、求解器和结果。纯文档修改运行文件检查即可。
4. 用截图说明布局变更，避免将缓存、原始会话或本机路径带入提交。
5. 提交 PR 时说明改动、验证范围及已知限制。

```bash
python3 tools/check_repository.py
```

提交身份请使用 GitHub 用户名与自己的 GitHub `noreply` 地址。不要提交真实姓名、私人邮箱、学号、未经公开授权的课堂资料或原始聊天截图。联合署名只用于真实的共同贡献，并使用本人确认的署名信息。

模型与 Simscape 组件需要 MathWorks 产品才能运行；不要将软件本身或商业工具箱打包入仓库。
