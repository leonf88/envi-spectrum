;+
; ����: ����
;
; ��ϵ��ʽ��chcdlf@126.com
;
;-
;+
;:Description:
;   ENVI ���ο��� 
;-
;��������
PRO ENVI_BATCH_CLEANUP,tlb
  WIDGET_CONTROL,tlb,get_UValue = pState
  PTR_FREE,pState
END

;�¼���Ӧ����
PRO ENVI_BATCH_EVENT,event
  COMPILE_OPT idl2
  WIDGET_CONTROL,event.TOP, get_UValue = pState
  
  ;�ر��¼�
  IF TAG_NAMES(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
    ;
    status = DIALOG_MESSAGE('�ر�?',/Question)
    IF status EQ 'No' THEN RETURN
    ;����ָ��
    ; PTR_FREE, pState
    WIDGET_CONTROL, event.TOP,/Destroy
    RETURN;
  ENDIF
  ;����ϵͳ��uname�����жϵ�������
  uName = WIDGET_INFO(event.ID,/uName)
  
  CATCH, error_status
  IF error_status NE 0 THEN BEGIN
    CATCH, /CANCEL
    void = DIALOG_MESSAGE(!ERROR_STATE.MSG ,/information)
    RETURN
  ENDIF
  
  ;
  CASE uname OF
    ;�˳�
    'exit': BEGIN
      status = DIALOG_MESSAGE('�ر�?', title = !SYS_Title, $
        /Question)
      IF status EQ 'No' THEN RETURN
      ENVI_BATCH_EXIT
      WIDGET_CONTROL, event.TOP,/Destroy
    END
    ;����
    'about': BEGIN
      void = DIALOG_MESSAGE(!SYS_Title+' V2.0'+STRING(13b)+'��ӭʹ�ã���ϵ����: chcdlf@gmail.com' ,/information)
    END
    ; ���TAB1�����ļ�
    'tab1ImportFile': BEGIN
      files = DIALOG_PICKFILE(/MULTIPLE_FILES, $
                              filter = '*.sli', $
                              title = !SYS_Title+' ���ļ�', $
                              path = (*pState).ORIROOT)
      IF N_ELEMENTS(files) EQ 0 or files[0] EQ '' THEN RETURN
      ;������ʾ�ļ�
      
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
    ;ѡ�����·��
    'tab1fOutSel' : BEGIN
      path = DIALOG_PICKFILE(/DIRECTORY, $
                                title = "ѡ�����·��", $
                                PATH = (*pState).ORIROOT)
      IF STRTRIM(path) EQ '' THEN path = (*pState).ORIROOT
      WIDGET_CONTROL, (*pState).tab1fOutText, set_value = path
    END
    ;����ִ��
    'tab1ExecRun': BEGIN
      ; ��ȡ���·��
      WIDGET_CONTROL,(*pState).tab1fOutText, get_Value = outPath
      outPath = STRTRIM(outPath)
      ; ���·�����Ϸ�������ѡ��
      IF outPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("���·������Ϊ�գ����������ã�")
        RETURN
      ENDIF   
      
      IF PTR_VALID((*pState).tab1InFiles) EQ 0 THEN RETURN
      ; ��ȡƽ������
      WIDGET_CONTROL,(*pState).tab1VarSmooth, get_Value = smoothVar
      ; ��ȡ����1
      WIDGET_CONTROL,(*pState).tab1VarTrough1, get_Value = troughVar1
      ; ��ȡ����2
      WIDGET_CONTROL,(*pState).tab1VarTrough2, get_Value = troughVar2
      ; ��ȡ�ļ��б�
      files = *((*pState).tab1InFiles)
;      ; ��ʼ��ENVI
      ENVI, /RESTORE_BASE_SAVE_FILES
      ENVI_BATCH_INIT, /NO_STATUS_WINDOW
;      
      FOR i=0,N_ELEMENTS(files)-1 DO BEGIN
        process, files[i], outPath, smoothvar, troughVar1, troughVar2 * 0.00001
      ENDFOR
      void = DIALOG_MESSAGE('������� ',TITLE = !sys_title,/infor)
    END
    'tab2InButton': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                title = "ѡ�������ļ�", $
                                filter = '*.csv', $
                                PATH = (*pState).ORIROOT)
      path = STRTRIM(path)
      IF path EQ '' THEN path = (*pState).ORIROOT
      WIDGET_CONTROL, (*pState).tab2InText, set_value = path
      
      path = FILE_DIRNAME(path)
      WIDGET_CONTROL, (*pState).tab2TypeGroup, get_value = tab2type
      CASE tab2type OF
          0: opath = path + PATH_SEP() + "������ʽ1"
          1: opath = path + PATH_SEP() + "������ʽ2"
          2: opath = path + PATH_SEP() + "������ʽ3"
      ENDCASE
      WIDGET_CONTROL, (*pState).tab2OutText, set_value = opath
    END
    'tab2OutButton': BEGIN
      path = DIALOG_PICKFILE(/DIRECTORY, $
                                title = "ѡ�����·��", $
                                PATH = (*pState).ORIROOT)
      IF STRTRIM(path) EQ '' THEN path = (*pState).ORIROOT
      
      WIDGET_CONTROL, (*pState).tab2TypeGroup, get_value = tab2type
      CASE tab2type OF
          0: opath = path + PATH_SEP() + "������ʽ1"
          1: opath = path + PATH_SEP() + "������ʽ2"
          2: opath = path + PATH_SEP() + "������ʽ3"
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
          0: opath = path + PATH_SEP() + "������ʽ1"
          1: opath = path + PATH_SEP() + "������ʽ2"
          2: opath = path + PATH_SEP() + "������ʽ3"
        ENDCASE
        WIDGET_CONTROL, (*pState).tab2OutText, set_value = opath
      ENDIF
    END
    'tab2ExecRun': BEGIN
      ; ��ȡ���·��
      WIDGET_CONTROL,(*pState).tab2OutText, get_Value = outPath
      outPath = STRTRIM(outPath)
      ; ���·�����Ϸ�������ѡ��
      IF outPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("���·������Ϊ�գ����������ã�")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab2InText, get_value = inPath
      inPath = STRTRIM(inPath)
      ; ���·�����Ϸ�������ѡ��
      IF inPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("�����ļ�����Ϊ�գ����������ã�")
        RETURN
      ENDIF 
      
      WIDGET_CONTROL, (*pState).tab2TypeGroup, get_value = type
      IF FILE_TEST(outPath, /DIRECTORY) eq 0 THEN BEGIN
        FILE_MKDIR, outPath
      ENDIF 
      
      spectral_cal, inPath, outPath, type
      void = DIALOG_MESSAGE('������� ',TITLE = !sys_title,/infor)
    END
    'tab3InButton1': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                title = "ѡ�������ļ�", $
                                filter = '*.csv', $
                                PATH = (*pState).ORIROOT)
      IF STRTRIM(path) NE '' THEN BEGIN
        (*pState).ORIROOT = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab3InText1, set_value = path
        WIDGET_CONTROL, (*pState).tab3InText2, get_value = ipath2
        WIDGET_CONTROL, (*pState).tab3OutText, get_value = opath
        IF ipath2 EQ '' THEN WIDGET_CONTROL, (*pState).tab3InText2, set_value = (*pState).ORIROOT 
        IF opath EQ '' THEN BEGIN
          outfile = (*pState).ORIROOT + PATH_SEP() + "ָ��.csv"
          WIDGET_CONTROL, (*pState).tab3OutText, set_value = outfile
        ENDIF 
      ENDIF
    END
    'tab3InButton2': BEGIN
        path = DIALOG_PICKFILE(/DIRECTORY, $
                                  title = "ѡ������·��", $
                                  filter = '*.sli', $
                                  PATH = (*pState).ORIROOT)
        
      IF STRTRIM(path) NE '' THEN BEGIN
        (*pState).ORIROOT = FILE_DIRNAME(path)
        WIDGET_CONTROL, (*pState).tab3InText2, set_value = path
        
        WIDGET_CONTROL, (*pState).tab3OutText, get_value = opath
        IF opath EQ '' THEN BEGIN
          outfile = (*pState).ORIROOT + PATH_SEP() + "ָ��.csv"
          WIDGET_CONTROL, (*pState).tab3OutText, set_value = outfile
        ENDIF
      ENDIF 
    END
    'tab3OutButton': BEGIN
      path = DIALOG_PICKFILE(/DIRECTORY, $
                                title = "ѡ�����·��", $
                                PATH = (*pState).ORIROOT)
      IF STRTRIM(path) EQ '' THEN path = (*pState).ORIROOT
      outfile = path + PATH_SEP() + "ָ��.csv"
      WIDGET_CONTROL, (*pState).tab3OutText, set_value = outfile
      (*pState).ORIROOT = path
    END
    'tab3ExecRun': BEGIN
      ; ��ȡ���·��
      WIDGET_CONTROL,(*pState).tab3OutText, get_Value = outfile
      outfile = STRTRIM(outfile)
      ; ���·�����Ϸ�������ѡ��
      outbasename = FILE_BASENAME(outfile)
      iscsv = STREGEX(outfile, ".csv") GT 0
      IF outfile EQ '' or outbasename EQ '' or iscsv EQ 0  THEN BEGIN
        void = DIALOG_MESSAGE("����ļ����Ϸ�������.csv��Ϊ�ļ���׺�������������ã�")
        RETURN
      ENDIF    
      WIDGET_CONTROL, (*pState).tab3InText1, get_value = inPath1
      inPath = STRTRIM(inPath1)
      ; ���·�����Ϸ�������ѡ��
      IF inPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("Y �����ļ�����Ϊ�գ����������ã�")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab3InText2, get_value = inPath2
      inPath = STRTRIM(inPath2)
      ; ���·�����Ϸ�������ѡ��
      IF inPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("SLI ����·������Ϊ�գ����������ã�")
        RETURN
      ENDIF 
      
      ; ��ʼ��ENVI
      ENVI, /RESTORE_BASE_SAVE_FILES
      ENVI_BATCH_INIT, /NO_STATUS_WINDOW
      outPath = FILE_DIRNAME(outfile) 
      IF FILE_TEST(outPath, /DIRECTORY) eq 0 THEN BEGIN
        FILE_MKDIR, outPath
      ENDIF 
      params_calc, inPath1, inPath2, outfile
      void = DIALOG_MESSAGE('������� ',TITLE = !sys_title,/infor)
    END
    'tab4InButton1': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                title = "ѡ�������ļ�", $
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
                                  title = "ѡ������·��", $
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
      ; ���·�����Ϸ�������ѡ��
      IF yPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("Y �����ļ�����Ϊ�գ����������ã�")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab4InText2, get_value = sliPath
      sliPath = STRTRIM(sliPath)
      ; ���·�����Ϸ�������ѡ��
      IF sliPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("SLI ����·������Ϊ�գ����������ã�")
        RETURN
      ENDIF 
      
;  yPath = "D:\Projects\lizhe\data\��������-mini.csv"
;  sliPath = "D:\Projects\lizhe\data\1-16�ŵ�λ��ʵ�����ʱ�׼�⡪��ENVI��ʽ"
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
      
      ; ��ʼ��ENVI
      ENVI, /RESTORE_BASE_SAVE_FILES
      ENVI_BATCH_INIT, /NO_STATUS_WINDOW
      res = BEST_NDVI(minA, maxA, minB, maxB, yPath, sliPath)
;      print, STRING(res, FORMAT='("��С���Σ�nm��", A0, "/n��󲨶Σ�nm��", A0, "\n���ϵ��", A0)')
      WIDGET_CONTROL, (*pState).tab4OutText, set_value = [ $
      STRING(res[0], FORMAT='("��С���Σ�nm����", A0)'), $
      STRING(res[1], FORMAT='("��󲨶Σ�nm����", A0)'), $
      STRING(res[2], FORMAT='("���ϵ����", A0)')] 
    END
    'tab5InButton1': BEGIN
      path = DIALOG_PICKFILE(/MUST_EXIST, $
                                title = "ѡ��ģ�����ļ�", $
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
                                  title = "ѡ����������ļ�", $
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
                                  title = "ѡ�����·��", $
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
      ; ���·�����Ϸ�������ѡ��
      IF samplePath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("��ģ�����ļ�����Ϊ�գ����������ã�")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab5TestsText2, get_value = testPath
      testPath = STRTRIM(testPath)
      ; ���·�����Ϸ�������ѡ��
      IF testPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("��ģ�����ļ�����Ϊ�գ����������ã�")
        RETURN
      ENDIF   
      WIDGET_CONTROL, (*pState).tab5OutText, get_value = outPath
      outPath = STRTRIM(outPath)
      ; ���·�����Ϸ�������ѡ��
      IF outPath EQ '' THEN BEGIN
        void = DIALOG_MESSAGE("���·������Ϊ�գ����������ã�")
        RETURN
      ENDIF 
      
      ; ��ʼ��ENVI
      
;  samplePath = "D:\Projects\lizhe\data\��ģ����1.csv"
;  testPath = "D:\Projects\lizhe\data\��������1.csv"
;  outPath = "D:\Projects\lizhe\data"
      outModel = outPath + PATH_SEP() + "��ģ���.csv"
      singel_model, samplePath, testPath, outModel, outPath
      void = DIALOG_MESSAGE("��ģ�����ļ�Ϊ��" + outModel)
    END
    ELSE:
  ENDCASE
  return

END
;
;--------------------------
;������ 
PRO MAIN
  ;
  COMPILE_OPT idl2
  ;��ʼ�������С
  sz = [800,600]
  ;����ϵͳ�������ɷ����޸�ϵͳ����
  DEFSYSV, '!SYS_Title', '�߹�����������ϵͳ'
  ;��������Ĵ���
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
  ;�����˵�
  fMenu = WIDGET_BUTTON(mBar, value ='�ļ�(&F)',/Menu)
  fExit = WIDGET_BUTTON(fMenu, value = '�˳�(&X)', uName = 'exit',/Sep)
  hMenu =  WIDGET_BUTTON(mBar, value ='����(&H)',/Menu)
  hHelp = WIDGET_BUTTON(hmenu, value = '����(&A)', uName = 'about',/Sep)

  WIDGET_CONTROL, tlb, /REALIZE
  ; tab�������
  wt = WIDGET_TAB(tlb)
  tab1 = WIDGET_BASE(wt, $
                    title = '�������շ��Զ���ȡ' , $
                    XSIZE = sz[0], YSIZE = sz[1], $
                    /FRAME, $
                    /ALIGN_CENTER, $
                    /COLUMN)
    
    tab1fListBase = WIDGET_BASE(tab1, XSIZE =sz[0], /FRAME, /ALIGN_CENTER, /COLUMN)
    tab1fLabel = WIDGET_LABEL(tab1fListBase, value ='�����ļ��б�')
    tab1fList = WIDGET_LIST(tab1fListBase, XSIZE = sz[0]/8, YSIZE = sz[1]/(35))
    
    ; ƽ����������
    tab1SmoothBase = WIDGET_BASE(tab1, XSIZE = sz[0], /ROW)
    tab1fLabel = WIDGET_LABEL(tab1SmoothBase, $
                        VALUE ='ƽ���������ã�', $
                        /ALIGN_RIGHT, $
                        XSIZE=120)
    tab1VarSmooth = WIDGET_SLIDER(tab1SmoothBase, $
                        VALUE = 10, $ 
                        XSIZE = 200, $
                        MINIMUM = 1, $
                        MAXIMUM = 100, $
                        UNAME = 'smoothVar')
                        
    ; ������ֵ����1
    tab1TroughBase1 = WIDGET_BASE(tab1, XSIZE = sz[0], /ROW)
    tab1fLabel = WIDGET_LABEL(tab1TroughBase1, $
                        VALUE ='����ʶ�𾫶�����1��', $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab1VarTrough1 = WIDGET_SLIDER(tab1TroughBase1, $
                        VALUE = 20, $ 
                        XSIZE = 200, $
                        MINIMUM = 1, $
                        MAXIMUM = 100, $
                        UNAME = 'troughVar1')
    ; ������ֵ����2
    tab1TroughBase2 = WIDGET_BASE(tab1, XSIZE = sz[0], /ROW)
    tab1fLabel = WIDGET_LABEL(tab1TroughBase2, $
                        VALUE ='����ʶ�𾫶�����2��', $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab1VarTrough2 = WIDGET_SLIDER(tab1TroughBase2, $
                        VALUE = 5, $ 
                        XSIZE = 200, $
                        MINIMUM = 1, $
                        MAXIMUM = 10, $
                        UNAME = 'troughVar2')
    ;
    ; ������ƽ���
    tab1fInBase = WIDGET_BASE(tab1, $
                        /ROW)
    tab1fInLabel = WIDGET_LABEL(tab1fInBase, $
                        VALUE = '�����ļ����ã�', $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)   
    tab1fInImport = WIDGET_BUTTON(tab1fInBase, $
                        value ='��������ļ�', $
                        uName = 'tab1ImportFile')    
    tab1fInClear = WIDGET_BUTTON(tab1fInBase, $
                        value ='��������б�', $
                        uName = 'tab1fInClear')  
      
    ; ����������ƽ���
    tab1fOutBase = WIDGET_BASE(tab1, /ROW)
    tab1fOutLabel = WIDGET_LABEL(tab1fOutBase, $
                        VALUE = '���·�����ã�', $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab1fOutText = WIDGET_TEXT(tab1fOutBase, $
                        VALUE ='', $ 
                        XSIZE = 50, $
                        /EDITABLE)               
    tab1fOutSel = WIDGET_BUTTON(tab1fOutBase, $
                        VALUE = '����', $
                        SENSITIVE = 1, $
                        UNAME ='tab1fOutSel')             
    ;ִ�а�ťbase
;    tab1ExecBase = WIDGET_BASE(tab1, $
;                        /ALIGN_LEFT, $
;                        /ROW)
;    ;״̬��������ʾ������
;    tab1ExecLabel = WIDGET_LABEL(tab1ExecBase, $
;                        VALUE = 'ִ�У�', $
;                        /ALIGN_RIGHT, $
;                        XSIZE = 100)
    tab1ExecRun = WIDGET_BUTTON(tab1, $
                        VALUE ='ִ��', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab1ExecRun')
                        
    tab2 = WIDGET_BASE(wt, title ='���ղ����任', /COLUMN)
    tab2TypeBase = WIDGET_BASE(tab2, XSIZE = sz[0], /BASE_ALIGN_CENTER,/ALIGN_CENTER, /ROW)
    tab2TypeGroup = CW_BGROUP(tab2TypeBase, $
                        ['������ʽ1��((��� * ����) - (ˮ0*ˮ1))/ ((��� * ����) + (ˮ0*ˮ1))', '������ʽ2������AB��ϵ������Ǿ���', '������ʽ3��B2 = 1/B���������е�AB���'], $
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
                        VALUE = "��������ļ���", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab2InText = WIDGET_TEXT(tab2InputBase, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab2InButton = WIDGET_BUTTON(tab2InputBase, $
                        VALUE = "����", $
                        UNAME = 'tab2InButton')
                            
    tab2OutputBase = WIDGET_BASE(tab2, /ROW)
    tab2OutLabel = WIDGET_LABEL(tab2OutputBase, $
                        VALUE = "���·�����ã�", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab2OutText = WIDGET_TEXT(tab2OutputBase, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab2OutButton = WIDGET_BUTTON(tab2OutputBase, $
                        VALUE = "����", $
                        UNAME = 'tab2OutButton')
    tab2ExecRun = WIDGET_BUTTON(tab2, $
                        VALUE ='ִ��', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab2ExecRun')
                            
  tab3 = WIDGET_BASE(wt, title ='ֲ��ָ������', /COLUMN)
    tab3InputBase1 = WIDGET_BASE(tab3, /ROW)
    tab3InLabel = WIDGET_LABEL(tab3InputBase1, $
                        VALUE = "��������ļ���", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab3InText1 = WIDGET_TEXT(tab3InputBase1, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab3InButton1 = WIDGET_BUTTON(tab3InputBase1, $
                        VALUE = "����", $
                        UNAME = 'tab3InButton1')
                            
    tab3InputBase2 = WIDGET_BASE(tab3, /ROW)
    tab3InLabel = WIDGET_LABEL(tab3InputBase2, $
                        VALUE = "SLI�ļ�·�����ã�", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab3InText2 = WIDGET_TEXT(tab3InputBase2, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab3InButton2 = WIDGET_BUTTON(tab3InputBase2, $
                        VALUE = "����", $
                        UNAME = 'tab3InButton2')
                            
    tab3OutputBase = WIDGET_BASE(tab3, /ROW)
    tab3OutLabel = WIDGET_LABEL(tab3OutputBase, $
                        VALUE = "���·�����ã�", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab3OutText = WIDGET_TEXT(tab3OutputBase, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab3OutButton = WIDGET_BUTTON(tab3OutputBase, $
                        VALUE = "����", $
                        UNAME = 'tab3OutButton')
    tab3ExecRun = WIDGET_BUTTON(tab3, $
                        VALUE ='ִ��', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab3ExecRun')
                        
  tab4 = WIDGET_BASE(wt, title ='���NDVI�������', /COLUMN)
    tab4A = WIDGET_BASE(tab4, /ROW)
    
    tab4MinA = CW_FIELD(tab4A, $
                        TITLE = 'A ������Сֵ��nm����', $
                        VALUE = '620', $
                        XSIZE = 10, $
                        /LONG, $
                        UNAME = 'tab4MinA')
    tab4MaxA = CW_FIELD(tab4A, $
                        TITLE = 'A �������ֵ��nm����', $
                        VALUE = '760', $
                        XSIZE = 10, $
                        /LONG, $
                        UNAME = 'tab4MaxA')
                           
    tab4B = WIDGET_BASE(tab4, /ROW)
    tab4MinB = CW_FIELD(tab4B, $
                        TITLE = 'B ������Сֵ��nm����', $
                        VALUE = '765', $
                        XSIZE = 10, $
                        /LONG, $
                        UNAME = 'tab4MinB')
                        
    tab4MaxB = CW_FIELD(tab4B, $
                        TITLE = 'B �������ֵ��nm����', $
                        VALUE = '1045', $
                        XSIZE = 10, $
                        /LONG, $
                        UNAME = 'tab4MaxB')
                        
    tab4InputBase1 = WIDGET_BASE(tab4, /ROW)
    tab4InLabel = WIDGET_LABEL(tab4InputBase1, $
                        VALUE = "��������ļ���", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab4InText1 = WIDGET_TEXT(tab4InputBase1, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab4InButton1 = WIDGET_BUTTON(tab4InputBase1, $
                        VALUE = "����", $
                        UNAME = 'tab4InButton1')
                        
    tab4InputBase2 = WIDGET_BASE(tab4, /ROW)
    tab4InLabel = WIDGET_LABEL(tab4InputBase2, $
                        VALUE = "SLI�ļ�·�����ã�", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab4InText2 = WIDGET_TEXT(tab4InputBase2, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab4InButton2 = WIDGET_BUTTON(tab4InputBase2, $
                        VALUE = "����", $
                        UNAME = 'tab4InButton2')
                            
    tab4OutputBase = WIDGET_BASE(tab4, /ROW)
    tab4OutLabel = WIDGET_LABEL(tab4OutputBase, $
                        VALUE = "NDVI��ֵ����Y��������ϵ����", $
                        /ALIGN_RIGHT, $
                        XSIZE = 200)
                        
    tab4OutText = WIDGET_TEXT(tab4OutputBase, $
                        VALUE = "", $
                        /ALIGN_LEFT, $
                        /WRAP, $
                        XSIZE = 40, $
                        YSIZE = 5)
    tab4ExecRun = WIDGET_BUTTON(tab4, $
                        VALUE ='ִ��', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab4ExecRun')
  
  tab5 = WIDGET_BASE(wt, title ='�ع�ģ��', /COLUMN)
    tab5InputBase1 = WIDGET_BASE(tab5, /ROW)
    tab5InLabel = WIDGET_LABEL(tab5InputBase1, $
                        VALUE = "��ģ�������ã�", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab5SamplesText1 = WIDGET_TEXT(tab5InputBase1, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab5InButton1 = WIDGET_BUTTON(tab5InputBase1, $
                        VALUE = "����", $
                        UNAME = 'tab5InButton1')
                            
    tab5InputBase2 = WIDGET_BASE(tab5, /ROW)
    tab5InLabel = WIDGET_LABEL(tab5InputBase2, $
                        VALUE = "����������ã�", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab5TestsText2 = WIDGET_TEXT(tab5InputBase2, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab5InButton2 = WIDGET_BUTTON(tab5InputBase2, $
                        VALUE = "����", $
                        UNAME = 'tab5InButton2')
                            
    tab5OutputBase = WIDGET_BASE(tab5, /ROW)
    tab5OutLabel = WIDGET_LABEL(tab5OutputBase, $
                        VALUE = "���·�����ã�", $
                        /ALIGN_RIGHT, $
                        XSIZE = 120)
    tab5OutText = WIDGET_TEXT(tab5OutputBase, $
                        VALUE = "", $
                        /EDITABLE, $
                        XSIZE = 50)
    tab5OutButton = WIDGET_BUTTON(tab5OutputBase, $
                        VALUE = "����", $
                        UNAME = 'tab5OutButton')
    tab5ExecRun = WIDGET_BUTTON(tab5, $
                        VALUE ='ִ��', $
                        /ALIGN_CENTER, $
                        UNAME = 'tab5ExecRun')
  ; �����������
  CENTERTLB, tlb
  
;    �ṹ�崫�ݲ���
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
