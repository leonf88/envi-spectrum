# Matlab 建模

## 单变量建模

### 1. Usage

使用之前修改 `model.m` 文件的 model_file 和 test_file 参数分别指定建模数据文件和模型检验数据文件

    $ matlab -nodesktop
    >> model

在工作目录下会得到 model-func.csv 建模文件以及存储有建模图片的 figures 文件夹

### 2. model/test file format

model_file 和 test_file 文件都是以逗号分隔的 CSV 文件。包含如下几列

 * Type：参数类型，如高验，中验，低验等；
 * Name：样板名称，一般和样板的文件名对应，如01-003等；
 * Y：反射率数值，从样本中获得；
 * SAIVI：（略）
 * NDVI：（略）
 * RVI：（略）
 * EVI：（略）
 * OSAVI：（略）
 * MSAVI：（略）
 * TCI：（略）
 * ARVI：（略）
 
文件内容如下：

    Type,Name,Y,SAIVI,NDVI,RVI,EVI,OSAVI,MSAVI,TCI,ARVI
    High,01-002,0.5316,0.3455,0.456,2.6765,0.2436,0.3434,0.227,2.3308,0.2876
    
需要**注意**的是 model 与 test 的数据列需要一致，对应列的数据是同一类数据



