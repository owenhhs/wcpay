# 调试检查清单

## 环境检查 ✓

- [ ] OrbStack Ubuntu实例已启动
- [ ] 已进入Ubuntu环境 (`orbstack shell ubuntu`)
- [ ] 项目文件已复制到Ubuntu
- [ ] 环境设置脚本已运行 (`setup-orbstack.sh`)

## WordPress配置 ✓

- [ ] WordPress已安装并可以访问
- [ ] 管理员账户已创建
- [ ] 调试模式已启用
- [ ] 文件权限正确设置

## WooCommerce配置 ✓

- [ ] WooCommerce插件已安装并激活
- [ ] WooCommerce设置向导已完成
- [ ] 货币设置为BRL
- [ ] 测试产品已创建

## 插件部署 ✓

- [ ] 支付插件文件已部署到 `/var/www/wordpress/wp-content/plugins/woocommerce-pay`
- [ ] 插件已在WordPress后台激活
- [ ] 插件在 `WooCommerce > 设置 > 支付` 中可见

## PIX网关配置 ✓

- [ ] PIX Payment网关已启用
- [ ] API Base URL已填写
- [ ] App ID已填写
- [ ] Sign Key已填写
- [ ] 沙盒模式已启用（测试时）
- [ ] 调试日志已启用

## 测试流程 ✓

- [ ] 可以访问商店首页
- [ ] 可以添加产品到购物车
- [ ] 可以进入结账页面
- [ ] PIX支付方式可见并可选
- [ ] 可以提交订单
- [ ] 订单已创建

## 日志检查 ✓

- [ ] WordPress调试日志正常记录 (`/var/www/wordpress/wp-content/debug.log`)
- [ ] WooCommerce日志正常记录
- [ ] PHP错误日志正常记录 (`/var/log/php8.1-fpm.log`)
- [ ] Nginx访问日志正常记录
- [ ] PIX支付日志正常记录

## 问题排查

如果遇到问题，检查：

1. **插件无法激活**
   - [ ] PHP版本 >= 7.2
   - [ ] 文件权限正确
   - [ ] 查看PHP错误日志

2. **网关不显示**
   - [ ] 货币设置为BRL
   - [ ] API凭证已填写
   - [ ] 插件已激活

3. **支付无法创建**
   - [ ] API凭证正确
   - [ ] 网络连接正常
   - [ ] 查看调试日志

4. **IPN回调无法接收**
   - [ ] 服务器可从外部访问
   - [ ] 端口已开放
   - [ ] 使用ngrok等工具测试

## 下一步

环境配置完成后：

- [ ] 创建测试订单
- [ ] 测试支付流程
- [ ] 查看订单状态
- [ ] 测试IPN回调
- [ ] 验证签名验证
- [ ] 检查日志输出

