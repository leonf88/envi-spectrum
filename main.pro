;+
; 作者: 梁帆
;
; 联系方式：chcdlf@126.com
;
;-
;+
;:Description:
;   ENVI 二次开发 
;-
;析构函数
PRO ENVI_BATCH_CLEANUP,tlb
  WIDGET_CONTROL,tlb,get_UValue = pState
  PTR_FREE,pState
END

;事件响应函数
PRO ENVI_BATCH_EVENT,event
  COMPILE_OPT idl2
  WIDGET_CONTROL,event.TOP, get_UValue = pState
  
  ;关闭事件
  IF TAG_NAMES(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
    ;
    status = DIALOG_MESSAGE('关闭?',/Question)
    IF status EQ 'No' THEN RETURN
    ;销毁指针
    ; PTR_FREE, pState
    WIDGET_CONTROL, event.TOP,/Destroy
    RETURN;
  ENDIF
  ;根据系统的uname进行判断点击的组件
  uName = WIDGET_INFO(event.ID,/uName)
  
  CATCH, error_status
  IF error_status NE 0 THEN BEGIN
    CATCH, /CANCEL
    void = DIALOG_MESSAGE(!ERROR_STATE.MSG ,/information)
    RETURN
  ENDIF
  
  ;
  CASE uname OF
    ;退出
    'exit': BEGIN
      status = DIALOG_MESSAGE('关闭?', title = !SYS_Title, $
        /Question)
      IF status EQ 'No' THEN RETURN
      ENVI_BATCH_EXIT
      WIDGET_CONTROL, event.TOP,/Destroy
    END
    ;关于
    'about': BEGIN
      void = DIALOG_MESSAGE(!SYS_Title+' V2.0'+STRING(13b)+'欢迎使用！联系作者: chcdlf@gmail.com' ,/information)
    END
    ; 添加TAB1输入文件
    'tab1ImportFile': BEGIN
      files = DIALOG_PICKFILE(/MULTIPLE_FILES, $
                              filter = '*.sli', $
                              title = !SYS_Title+' 打开文件', $
                              path = (*pState).ORIROOT)
      IF N_ELEMENTS(files) EQ 0 or files[0] EQ '' THEN RETURN
      ;设置显示文件
      
      print, n_elements((*pState).tab1InFiles)
      IF PTR_VALID((*pState).tab1InFiles) EQ 0 THEN BEGIN
        (*pState).tab1InFiles = PTR_NEW(files)
      ENDIF ELSE BEGIN
        orig_files = *((*pState).tab1InFiles)
        orig_files = [orig_files, files]
        orig_files = orig_files[UNIQ(orig_files, SORT(orig_files))] 
        (*pState).tab1InFiles = PTR_NEW(orig_files)
      ENDELSE
      
      WIDGET_CONTROL, (*pState).tab1fList, set_value = *((*pState).tab1InFiles)
      (*pState).ORIROOT = FILE_DIRNAME(files[0])
      WIDGET_CONTROL, (*pState).tab1fOutText, get_value = path
      IF path EQ '' and (*pState).ORIROOT NE '' THEN WIDGET_CONTROL, (*pState).tab1fOutText, set_value = (*pState).ORIROOT
    END
    'tab1fInClear': BEGIN
      (*pState).tab1InFiles = PTR_NEW()
      WIDGET_CONTROL, (*pState).tab1fList, set_value = ''
    END
    ;选择输出路径
    'tab1fOutSel' : BEGIN
      path = DIALOG_PICKFILE(/DIRECTORY, $
                                title = "选择输出路径", $
                                PATH = (*pState).ORIROOT)
      IF STRTRIM(path) EQ '' THEN path = (*pState).ORIROOT
      WIDGET_CONTROL, (*pState).tab1fOutText, set_value = path
    END
    ;功能执行
    'tab1ExecRun': BEGIN
      ; 获取输出路径
      WIDGET_CONTROL,(*pState).tab1fOutText, get_Value = outPath
      outPath = STRTRIM(outPath)
      ; 输出路径不合法，重新选择
      IF outPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("输出路径不能为空，请重新设置！")
        RETURN
      ENDIF   
      
      IF PTR_VALID((*pState).tab1InFiles) EQ 0 THEN RETURN
      ; 获取平滑参数
      WIDGET_CONTROL,(*pState).tab1VarSmooth, get_Value = smoothVar
      ; 获取参数1
      WIDGET_CONTROL,(*pState).tab1VarTrough1, get_Value = troughVar1
      ; 获取参数2
      WIDGET_CONTROL,(*pState).tab1VarTrough2, get_Value = troughVar2
      ; 获取文件列表
      files = *((*pState).tab1InFiles)
;      ; 初始化ENVI
      ENVI, /RESTORE_BASE_SAVE_FILES
      ENVI_BATCH_INIT, /NO_STATUS_WINDOW
;      
      FOR i=0,N_ELEMENTS(files)-1 DO BEGIN
        process, files[i], outPath, smoothvar, troughVar1, troughVar2 * 0.00001
      ENDFOR
      void = DIALOG_MESSAGE('处理完成 ',TITLE = !sys_title,/infor)
    END
    'tab2InButton': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                title = "选择输入文件", $
                                filter = '*.csv', $
                                PATH = (*pState).ORIROOT)
      path = STRTRIM(path)
      IF path EQ '' THEN path = (*pState).ORIROOT
      WIDGET_CONTROL, (*pState).tab2InText, set_value = path
      
      path = FILE_DIRNAME(path)
      WIDGET_CONTROL, (*pState).tab2TypeGroup, get_value = tab2type
      CASE tab2type OF
          0: opath = path + PATH_SEP() + "计算形式1"
          1: opath = path + PATH_SEP() + "计算形式2"
          2: opath = path + PATH_SEP() + "计算形式3"
      ENDCASE
      WIDGET_CONTROL, (*pState).tab2OutText, set_value = opath
    END
    'tab2OutButton': BEGIN
      path = DIALOG_PICKFILE(/DIRECTORY, $
                                title = "选择输出路径", $
                                PATH = (*pState).ORIROOT)
      IF STRTRIM(path) EQ '' THEN path = (*pState).ORIROOT
      
      WIDGET_CONTROL, (*pState).tab2TypeGroup, get_value = tab2type
      CASE tab2type OF
          0: opath = path + PATH_SEP() + "计算形式1"
          1: opath = path + PATH_SEP() + "计算形式2"
          2: opath = path + PATH_SEP() + "计算形式3"
      ENDCASE
      WIDGET_CONTROL, (*pState).tab2OutText, set_value = opath
      (*pState).ORIROOT = path
    END
    'specCalType': BEGIN
      WIDGET_CONTROL, (*pState).tab2OutText, get_value = path
      IF path NE '' THEN BEGIN 
        path = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab2TypeGroup, get_value = tab2type
        CASE tab2type OF
          0: opath = path + PATH_SEP() + "计算形式1"
          1: opath = path + PATH_SEP() + "计算形式2"
          2: opath = path + PATH_SEP() + "计算形式3"
        ENDCASE
        WIDGET_CONTROL, (*pState).tab2OutText, set_value = opath
      ENDIF
    END
    'tab2ExecRun': BEGIN
      ; 获取输出路径
      WIDGET_CONTROL,(*pState).tab2OutText, get_Value = outPath
      outPath = STRTRIM(outPath)
      ; 输出路径不合法，重新选择
      IF outPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("输出路径不能为空，请重新设置！")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab2InText, get_value = inPath
      inPath = STRTRIM(inPath)
      ; 输出路径不合法，重新选择
      IF inPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("输入文件不能为空，请重新设置！")
        RETURN
      ENDIF 
      
      WIDGET_CONTROL, (*pState).tab2TypeGroup, get_value = type
      IF FILE_TEST(outPath, /DIRECTORY) eq 0 THEN BEGIN
        FILE_MKDIR, outPath
      ENDIF 
      
      spectral_cal, inPath, outPath, type
      void = DIALOG_MESSAGE('处理完成 ',TITLE = !sys_title,/infor)
    END
    'tab3InButton1': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                title = "选择输入文件", $
                                filter = '*.csv', $
                                PATH = (*pState).ORIROOT)
      IF STRTRIM(path) NE '' THEN BEGIN
        (*pState).ORIROOT = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab3InText1, set_value = path
        WIDGET_CONTROL, (*pState).tab3InText2, get_value = ipath2
        WIDGET_CONTROL, (*pState).tab3OutText, get_value = opath
        IF ipath2 EQ '' THEN WIDGET_CONTROL, (*pState).tab3InText2, set_value = (*pState).ORIROOT 
        IF opath EQ '' THEN BEGIN
          outfile = (*pState).ORIROOT + PATH_SEP() + "指数.csv"
          WIDGET_CONTROL, (*pState).tab3OutText, set_value = outfile
        ENDIF 
      ENDIF
    END
    'tab3InButton2': BEGIN
        path = DIALOG_PICKFILE(/DIRECTORY, $
                                  title = "选择输入路径", $
                                  filter = '*.sli', $
                                  PATH = (*pState).ORIROOT)
        
      IF STRTRIM(path) NE '' THEN BEGIN
        (*pState).ORIROOT = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab3InText2, set_value = path
        
        WIDGET_CONTROL, (*pState).tab3OutText, get_value = opath
        IF opath EQ '' THEN BEGIN
          outfile = (*pState).ORIROOT + PATH_SEP() + "指数.csv"
          WIDGET_CONTROL, (*pState).tab3OutText, set_value = outfile
        ENDIF
      ENDIF 
    END
    'tab3OutButton': BEGIN
      path = DIALOG_PICKFILE(/DIRECTORY, $
                                title = "选择输出路径", $
                                PATH = (*pState).ORIROOT)
      IF STRTRIM(path) EQ '' THEN path = (*pState).ORIROOT
      outfile = path + PATH_SEP() + "指数.csv"
      WIDGET_CONTROL, (*pState).tab3OutText, set_value = outfile
      (*pState).ORIROOT = path
    END
    'tab3ExecRun': BEGIN
      ; 获取输出路径
      WIDGET_CONTROL,(*pState).tab3OutText, get_Value = outfile
      outfile = STRTRIM(outfile)
      ; 输出路径不合法，重新选择
      outbasename = FILE_BASENAME(outfile)
      iscsv = STREGEX(outfile, ".csv") GT 0
      IF outfile EQ '' or outbasename EQ '' or iscsv EQ 0  THEN BEGIN
        void = DIALOG_MESSAGE("输出文件不合法（需以.csv作为文件后缀），请重新设置！")
        RETURN
      ENDIF    
      WIDGET_CONTROL, (*pState).tab3InText1, get_value = inPath1
      inPath = STRTRIM(inPath1)
      ; 输出路径不合法，重新选择
      IF inPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("Y 输入文件不能为空，请重新设置！")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab3InText2, get_value = inPath2
      inPath = STRTRIM(inPath2)
      ; 输出路径不合法，重新选择
      IF inPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("SLI 输入路径不能为空，请重新设置！")
        RETURN
      ENDIF 
      
      ; 初始化ENVI
      ENVI, /RESTORE_BASE_SAVE_FILES
      ENVI_BATCH_INIT, /NO_STATUS_WINDOW
      outPath = FILE_DIRNAME(outfile) 
      IF FILE_TEST(outPath, /DIRECTORY) eq 0 THEN BEGIN
        FILE_MKDIR, outPath
      ENDIF 
      params_calc, inPath1, inPath2, outfile
      void = DIALOG_MESSAGE('处理完成 ',TITLE = !sys_title,/infor)
    END
    'tab4InButton1': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                title = "选择输入文件", $
                                filter = '*.csv', $
                                PATH = (*pState).ORIROOT)
      path = STRTRIM(path)
      print, path
      IF STRTRIM(path) NE '' THEN BEGIN
        (*pState).ORIROOT = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab4InText1, set_value = path
        WIDGET_CONTROL, (*pState).tab4InText2, get_value = ipath2
        IF ipath2 EQ '' THEN WIDGET_CONTROL, (*pState).tab4InText2, set_value = (*pState).ORIROOT 
      ENDIF
    END
    'tab4InButton2': BEGIN
        path = DIALOG_PICKFILE(/DIRECTORY, $
                                  title = "选择输入路径", $
                                  filter = '*.sli', $
                                  PATH = (*pState).ORIROOT)
        
      IF STRTRIM(path) NE '' THEN BEGIN
        (*pState).ORIROOT = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab4InText2, set_value = path
      ENDIF 
    END
    'tab4ExecRun': BEGIN
    
      WIDGET_CONTROL, (*pState).tab4InText1, get_value = yPath
      yPath = STRTRIM(yPath)
      ; 输出路径不合法，重新选择
      IF yPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("Y 输入文件不能为空，请重新设置！")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab4InText2, get_value = sliPath
      sliPath = STRTRIM(sliPath)
      ; 输出路径不合法，重新选择
      IF sliPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("SLI 输入路径不能为空，请重新设置！")
        RETURN
      ENDIF 
      
;  yPath = "D:\Projects\lizhe\data\遍历数据-mini.csv"
;  sliPath = "D:\Projects\lizhe\data\1-16号点位真实反射率标准库——ENVI格式"
;  minA = 620
;  maxA = 760
;  minB = 765
;  maxB = 1045
      WIDGET_CONTROL, (*pState).tab4MinA, get_value = minA
      WIDGET_CONTROL, (*pState).tab4MaxA, get_value = maxA
      WIDGET_CONTROL, (*pState).tab4MinB, get_value = minB
      WIDGET_CONTROL, (*pState).tab4MaxB, get_value = maxB
      
      minA = LONG(minA)
      maxA = LONG(maxA)
      minB = LONG(minB)
      maxB = LONG(maxB)
      
      ; 初始化ENVI
      ENVI, /RESTORE_BASE_SAVE_FILES
      ENVI_BATCH_INIT, /NO_STATUS_WINDOW
      res = BEST_NDVI(minA, maxA, minB, maxB, yPath, sliPath)
;      print, STRING(res, FORMAT='("最小波段（nm）", A0, "/n最大波段（nm）", A0, "\n相关系数", A0)')
      WIDGET_CONTROL, (*pState).tab4OutText, set_value = [ $
      STRING(res[0], FORMAT='("最小波段（nm）：", A0)'), $
      STRING(res[1], FORMAT='("最大波段（nm）：", A0)'), $
      STRING(res[2], FORMAT='("相关系数：", A0)')] 
    END
    'tab5InButton1': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                title = "选择建模样本文件", $
                                filter = '*.csv', $
                                PATH = (*pState).ORIROOT)
      path = STRTRIM(path)
      IF path NE '' THEN BEGIN
        (*pState).ORIROOT = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab5SamplesText1, set_value = path
        WIDGET_CONTROL, (*pState).tab5OutText, get_value = opath
        IF opath EQ '' THEN BEGIN
          opath = (*pState).ORIROOT
          WIDGET_CONTROL, (*pState).tab5OutText, set_value = opath
        ENDIF 
      ENDIF
    END
    'tab5InButton2': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                  title = "选择测试样本文件", $
                                  filter = '*.csv', $
                                  PATH = (*pState).ORIROOT)
      path = STRTRIM(path)
      IF path NE '' THEN BEGIN
        (*pState).ORIROOT = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab5TestsText2, set_value = path
        WIDGET_CONTROL, (*pState).tab5OutText, get_value = opath
        IF opath EQ '' THEN BEGIN
          opath = (*pState).ORIROOT
          WIDGET_CONTROL, (*pState).tab5OutText, set_value = opath
        ENDIF 
      ENDIF
    END
    'tab5OutButton': BEGIN
      path = DIALOG_PICKFILE(/DIRECTORY, $
                                  title = "选择输出路径", $
                                  PATH = (*pState).ORIROOT)
      path = STRTRIM(path)
      IF path NE '' THEN BEGIN
        (*pState).ORIROOT = path
        WIDGET_CONTROL, (*pState).tab5OutText, set_value = path
      ENDIF
    END
    'tab5ExecRun': BEGIN    
      WIDGET_CONTROL, (*pState).tab5SamplesText1, get_value = samplePath
      samplePath = STRTRIM(samplePath)
      ; 输出路径不合法，重新选择
      IF samplePath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("建模输入文件不能为空，请重新设置！")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab5TestsText2, get_value = testPath
      testPath = STRTRIM(testPath)
      ; 输出路径不合法，重新选择
      IF testPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("建模输入文件不能为空，请重新设置！")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab5OutText, get_value = outPath
      outPath = STRTRIM(outPath)
      ; 输出路径不合法，重新选择
      IF outPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("输出路径不能为空，请重新设置！")
        RETURN
      ENDIF 
      
      ; 初始化ENVI
      
;  samplePath = "D:\Projects\lizhe\data\建模样本1.csv"
;  testPath = "D:\Projects\lizhe\data\检验样本1.csv"
;  outPath = "D:\Projects\lizhe\data"
      outModel = outPath + PATH_SEP() + "建模结果.csv"
      singel_model, samplePath, testPath, outModel, outPath
      void = DIALOG_MESSAGE("建模数据文件为：" + outModel)
    END
    ELSE:
  ENDCASE
  return

END
;
;--------------------------
;主函数 
PRO MAIN
  ;
  COMPILE_OPT idl2
  ;初始化组件大小
  sz = [800,600]
  ;设置系统变量，可方便修改系统标题
  DEFSYSV, '!SYS_Title', '高光谱特征分析系统'
  ;创建界面的代码
;  tlb = WIDGET_BASE(MBAR = mBar, $
;                      /COLUMN , $ 
;                      title = !SYS_Title, $
;                      /Tlb_Kill_Request_Events, $
;                      tlb_frame_attr = 1, $
;                      Map = 0)
  tlb = WIDGET_BASE(TITLE = !SYS_Title, $
                    MBAR = mBar, $
                    /Tlb_Kill_Request_Events, $
                    tlb_frame_attr = 1, $
                    Map = 0, $
                    /COLUMN)
  ;创建菜单
  fMenu = WIDGET_BUTTON(mBar, value ='文件(&F)',/Menu)
  fExit = WIDGET_BUTTON(fMenu, value = '退出(&X)', uName = 'exit',/Sep)
  hMenu =  WIDGET_BUTTON(mBar, value ='帮助(&H)',/Menu)
  hHelp = WIDGET_BUTTON(hmenu, value = '关于(&A)', uName = 'about',/Sep)

  WIDGET_CONTROL, tlb, /REALIZE
  ; tab界面组件
  wt = WIDGET_TAB(tlb)
  tab1 = WIDGET_BASE(wt, $
                    title = '光谱吸收峰自动提取' , $
                    XSIZE = sz[0], YSIZE = sz[1], $
                    /FRAME, $
                    /ALIGN_CENTER, $
                    /COLUMN)
    
    tab1fListBase = WIDGET_BASE(tab1, XSIZE =sz[0], /FRAME, /ALIGN_CENTER, /COLUMN)
    tab1fLabel = WIDGET_LABEL(tab1fListBase, value ='输入文件列表')
    tab1fList = WIDGET_LIST(tab1fListBase, XSIZE = sz[0]/8, YSIZE = sz[1]/(35))
    
    ; 平滑参数设置
    tab1SmoothBase = WIDGET_BASE(tab1, XSIZE = sz[0], /ROW)
    tab1fLabel = WIDGET_LABEL(tab1SmoothBase, $
                        VALUE ='平滑参数设置：', $
                        /ALIGN_RIGHT, $
                        XSIZE=120)
    tab1VarSmooth = WIDGET_SLIDER(tab1SmoothBase, $
                        VALUE = 10, $ 
                        XSIZE = 200, $
                        MINIMUM = 1, $
                        MAXIMUM = 100, $
                        UNAME = 'smoothVar')
                        
    ; 精度阈值设置1
    tab1TroughBase1 = WIDGET_BASE(tab1, XSIZE = sz[0], /ROW)
    tab1fLabel = WIDGET_LABEL(tab1TroughBase1, $
                        VALUE ='波谷识别精度设置1：', $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab1VarTrough1 = WIDGET_SLIDER(tab1TroughBase1, $
                        VALUE = 20, $ 
                        XSIZE = 200, $
                        MINIMUM = 1, $
                        MAXIMUM = 100, $
                        UNAME = 'troughVar1')
    ; 精度阈值设置2
    tab1TroughBase2 = WIDGET_BASE(tab1, XSIZE = sz[0], /ROW)
    tab1fLabel = WIDGET_LABEL(tab1TroughBase2, $
                        VALUE ='波谷识别精度设置2：', $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab1VarTrough2 = WIDGET_SLIDER(tab1TroughBase2, $
                        VALUE = 5, $ 
                        XSIZE = 200, $
                        MINIMUM = 1, $
                        MAXIMUM = 10, $
                        UNAME = 'troughVar2')
    ;
    ; 输入控制界面
    tab1fInBase = WIDGET_BASE(tab1, $
                        /ROW)
    tab1fInLabel = WIDGET_LABEL(tab1fInBase, $
                        VALUE = '输入文件设置：', $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)   
    tab1fInImport = WIDGET_BUTTON(tab1fInBase, $
                        value ='添加输入文件', $
                        uName = 'tab1ImportFile')    
    tab1fInClear = WIDGET_BUTTON(tab1fInBase, $
                        value ='清空输入列表', $
                        uName = 'tab1fInClear')  
      
    ; 输出参数控制界面
    tab1fOutBase = WIDGET_BASE(tab1, /ROW)
    tab1fOutLabel = WIDGET_LABEL(tab1fOutBase, $
                        VALUE = '输出路径设置：', $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab1fOutText = WIDGET_TEXT(tab1fOutBase, $
                        VALUE ='', $ 
                        XSIZE = 50, $
                        /EDITABLE)               
    tab1fOutSel = WIDGET_BUTTON(tab1fOutBase, $
                        VALUE = '设置', $
                        SENSITIVE = 1, $
                        UNAME ='tab1fOutSel')             
    ;执行按钮base
;    tab1ExecBase = WIDGET_BASE(tab1, $
;                        /ALIGN_LEFT, $
;                        /ROW)
;    ;状态栏，仅显示进度条
;    tab1ExecLabel = WIDGET_LABEL(tab1ExecBase, $
;                        VALUE = '执行：', $
;                        /ALIGN_RIGHT, $
;                        XSIZE = 100)
    tab1ExecRun = WIDGET_BUTTON(tab1, $
                        VALUE ='执行', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab1ExecRun')
                        
    tab2 = WIDGET_BASE(wt, title ='吸收参量变换', /COLUMN)
    tab2TypeBase = WIDGET_BASE(tab2, XSIZE = sz[0], /BASE_ALIGN_CENTER,/ALIGN_CENTER, /ROW)
    tab2TypeGroup = CW_BGROUP(tab2TypeBase, $
                        ['计算形式1：((红谷 * 蓝谷) - (水0*水1))/ ((红谷 * 蓝谷) + (水0*水1))', '计算形式2：计算AB组合的上三角矩阵', '计算形式3：B2 = 1/B，计算所有的AB组合'], $
                        /COLUMN, $
                        /EXCLUSIVE, $
                        /NO_RELEASE, $
                        SET_VALUE=0, $
                        XSIZE = 490, $
                        XPAD = 33, $
                        /FRAME, $
                        UNAME = 'specCalType')
      
    tab2InputBase = WIDGET_BASE(tab2, /ROW)
    tab2InLabel = WIDGET_LABEL(tab2InputBase, $
                        VALUE = "输入遍历文件：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab2InText = WIDGET_TEXT(tab2InputBase, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab2InButton = WIDGET_BUTTON(tab2InputBase, $
                        VALUE = "设置", $
                        UNAME = 'tab2InButton')
                            
    tab2OutputBase = WIDGET_BASE(tab2, /ROW)
    tab2OutLabel = WIDGET_LABEL(tab2OutputBase, $
                        VALUE = "输出路径设置：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab2OutText = WIDGET_TEXT(tab2OutputBase, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab2OutButton = WIDGET_BUTTON(tab2OutputBase, $
                        VALUE = "设置", $
                        UNAME = 'tab2OutButton')
    tab2ExecRun = WIDGET_BUTTON(tab2, $
                        VALUE ='执行', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab2ExecRun')
                            
  tab3 = WIDGET_BASE(wt, title ='植被指数计算', /COLUMN)
    tab3InputBase1 = WIDGET_BASE(tab3, /ROW)
    tab3InLabel = WIDGET_LABEL(tab3InputBase1, $
                        VALUE = "输入遍历文件：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab3InText1 = WIDGET_TEXT(tab3InputBase1, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab3InButton1 = WIDGET_BUTTON(tab3InputBase1, $
                        VALUE = "设置", $
                        UNAME = 'tab3InButton1')
                            
    tab3InputBase2 = WIDGET_BASE(tab3, /ROW)
    tab3InLabel = WIDGET_LABEL(tab3InputBase2, $
                        VALUE = "SLI文件路径设置：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab3InText2 = WIDGET_TEXT(tab3InputBase2, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab3InButton2 = WIDGET_BUTTON(tab3InputBase2, $
                        VALUE = "设置", $
                        UNAME = 'tab3InButton2')
                            
    tab3OutputBase = WIDGET_BASE(tab3, /ROW)
    tab3OutLabel = WIDGET_LABEL(tab3OutputBase, $
                        VALUE = "输出路径设置：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab3OutText = WIDGET_TEXT(tab3OutputBase, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab3OutButton = WIDGET_BUTTON(tab3OutputBase, $
                        VALUE = "设置", $
                        UNAME = 'tab3OutButton')
    tab3ExecRun = WIDGET_BUTTON(tab3, $
                        VALUE ='执行', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab3ExecRun')
                        
  tab4 = WIDGET_BASE(wt, title ='最佳NDVI波段组合', /COLUMN)
    tab4A = WIDGET_BASE(tab4, /ROW)
    
    tab4MinA = CW_FIELD(tab4A, $
                        TITLE = 'A 波段最小值（nm）：', $
                        VALUE = '620', $
                        XSIZE = 10, $
                        /LONG, $
                        UNAME = 'tab4MinA')
    tab4MaxA = CW_FIELD(tab4A, $
                        TITLE = 'A 波段最大值（nm）：', $
                        VALUE = '760', $
                        XSIZE = 10, $
                        /LONG, $
                        UNAME = 'tab4MaxA')
                           
    tab4B = WIDGET_BASE(tab4, /ROW)
    tab4MinB = CW_FIELD(tab4B, $
                        TITLE = 'B 波段最小值（nm）：', $
                        VALUE = '765', $
                        XSIZE = 10, $
                        /LONG, $
                        UNAME = 'tab4MinB')
                        
    tab4MaxB = CW_FIELD(tab4B, $
                        TITLE = 'B 波段最大值（nm）：', $
                        VALUE = '1045', $
                        XSIZE = 10, $
                        /LONG, $
                        UNAME = 'tab4MaxB')
                        
    tab4InputBase1 = WIDGET_BASE(tab4, /ROW)
    tab4InLabel = WIDGET_LABEL(tab4InputBase1, $
                        VALUE = "输入遍历文件：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab4InText1 = WIDGET_TEXT(tab4InputBase1, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab4InButton1 = WIDGET_BUTTON(tab4InputBase1, $
                        VALUE = "设置", $
                        UNAME = 'tab4InButton1')
                        
    tab4InputBase2 = WIDGET_BASE(tab4, /ROW)
    tab4InLabel = WIDGET_LABEL(tab4InputBase2, $
                        VALUE = "SLI文件路径设置：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab4InText2 = WIDGET_TEXT(tab4InputBase2, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab4InButton2 = WIDGET_BUTTON(tab4InputBase2, $
                        VALUE = "设置", $
                        UNAME = 'tab4InButton2')
                            
    tab4OutputBase = WIDGET_BASE(tab4, /ROW)
    tab4OutLabel = WIDGET_LABEL(tab4OutputBase, $
                        VALUE = "NDVI数值组与Y的最大相关系数：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 200)
                        
    tab4OutText = WIDGET_TEXT(tab4OutputBase, $
                        VALUE = "", $
                        /ALIGN_LEFT, $
                        /WRAP, $
                        XSIZE = 40, $
                        YSIZE = 5)
    tab4ExecRun = WIDGET_BUTTON(tab4, $
                        VALUE ='执行', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab4ExecRun')
  
  tab5 = WIDGET_BASE(wt, title ='回归模型', /COLUMN)
    tab5InputBase1 = WIDGET_BASE(tab5, /ROW)
    tab5InLabel = WIDGET_LABEL(tab5InputBase1, $
                        VALUE = "建模样本设置：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab5SamplesText1 = WIDGET_TEXT(tab5InputBase1, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab5InButton1 = WIDGET_BUTTON(tab5InputBase1, $
                        VALUE = "设置", $
                        UNAME = 'tab5InButton1')
                            
    tab5InputBase2 = WIDGET_BASE(tab5, /ROW)
    tab5InLabel = WIDGET_LABEL(tab5InputBase2, $
                        VALUE = "检测样本设置：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab5TestsText2 = WIDGET_TEXT(tab5InputBase2, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab5InButton2 = WIDGET_BUTTON(tab5InputBase2, $
                        VALUE = "设置", $
                        UNAME = 'tab5InButton2')
                            
    tab5OutputBase = WIDGET_BASE(tab5, /ROW)
    tab5OutLabel = WIDGET_LABEL(tab5OutputBase, $
                        VALUE = "输出路径设置：", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab5OutText = WIDGET_TEXT(tab5OutputBase, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab5OutButton = WIDGET_BUTTON(tab5OutputBase, $
                        VALUE = "设置", $
                        UNAME = 'tab5OutButton')
    tab5ExecRun = WIDGET_BUTTON(tab5, $
                        VALUE ='执行', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab5ExecRun')
  ; 操作界面居中
  CENTERTLB, tlb
  
;    结构体传递参数
  state = {tlb    : tlb, $ 
      tab1fList     : tab1fList, $
      tab1VarSmooth : tab1VarSmooth, $
      tab1VarTrough1 : tab1VarTrough1, $
      tab1VarTrough2 : tab1VarTrough2, $
      tab1InFiles   : PTR_NEW(), $
      tab1fOutText  : tab1fOutText, $
      tab2TypeGroup : tab2TypeGroup, $
      tab2InText    : tab2InText, $
      tab2OutText   : tab2OutText, $
      tab3InText1   : tab3InText1, $
      tab3InText2   : tab3InText2, $
      tab3OutText   : tab3OutText, $
      tab4InText1   : tab4InText1, $
      tab4InText2   : tab4InText2, $
      tab4MinA      : tab4MinA, $
      tab4MaxA      : tab4MaxA, $
      tab4MinB      : tab4MinB, $
      tab4MaxB      : tab4MaxB, $
      tab4OutText   : tab4OutText, $
      tab5SamplesText1  : tab5SamplesText1, $
      tab5TestsText2    : tab5TestsText2, $
      tab5OutText       : tab5OutText, $
      oriRoot       : ''}
    pState = PTR_NEW(state, /no_copy)
  WIDGET_CONTROL, tlb, /REALIZE, /MAP, SET_UVALUE = pState
  XMANAGER, 'ENVI_BATCH', tlb, /NO_BLOCK, $
          cleanup ='ENVI_BATCH_CLEANUP'
END
