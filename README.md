# envi-spectrum
Envi IDL 二次开发，去包络线提取光谱特征

## 去包络线

算法过程可以参见 高教社，童庆禧、张兵、郑兰芬《高光谱遥感 ----原理、技术与应用》137页。
另外，也有一个 [BBS 帖子][1]可以参考。
实现过程中发现需要做很多去噪的工作，基本方法是求导和平滑，这样会带来误差，但也基本可用。

## 其他

本工程还包括了其它功能，在此不一一列出。

## 关于编码

工程由于使用中文，默认编码方式是 GBK。在 IDL 打开
`File -> Properties -> Resource -> Text file encoding`
进行修改。


[1]: http://bbs.sciencenet.cn/thread-1116920-1-1.html
