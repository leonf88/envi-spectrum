; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvcommandline__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;; CLASS_NAME:
;;   IDLitsrvCommandLine
;;
;; Purpose:
;;   This file implements a service object that encapsulates access to
;;   the IDL command line. It provides methods to return the contents
;;   of the command line variables as well as import data from items
;;   that the command line contains into the tools data manager.
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitsrvCommandLine::Init
;;
;; Purpose:
;; The constructor of the IDLitsrvCommandLine object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitsrvCommandLine::Init, _EXTRA=_SUPER
    compile_opt idl2, hidden
    return, self->IDLitOperation::Init(_EXTRA=_SUPER)
end

;-------------------------------------------------------------------------
;; IDLitsrvCommandLine::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitsrvCommandLine object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitsrvCommandLine::Cleanup
    compile_opt idl2, hidden
    self->IDLitOperation::Cleanup
end
;;---------------------------------------------------------------------------
;; Export to CL section
;;---------------------------------------------------------------------------
;; IDLitsrvCommandLine::_InjectIDLVariable
;;
;; Purpose:
;;   Used to place a value in the command line, main scope of IDL.
;;
;; Parameters:
;;   strName   - The name of the variable to create
;;
;;   Value     - The value of the variable to create.
;;
;; Keywords:
;;  OVERWRITE   - Overwrite existing variables.
;;
;; Return Value
;;   0  - Error
;;   1  - Success
;;  -1  - The variable already exists
;;
;;---------------------------------------------------------------------------
function IDLitsrvCommandLine::_InjectIDLVariable, strName, value, $
                                              OVERWRITE=OVERWRITE
  ;; Pragmas
  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch,/cancel
    return, 0
  endif

    ; Get a valid IDL name
    varName = strupcase(strName)

    if(not keyword_set(overwrite))then begin
        ; Check to see if the variable already exists.
        strCurrentVars = SCOPE_VARNAME(LEVEL=1, COUNT=count)
        if (count gt 0) && (MAX(strCurrentVars eq varName) eq 1) then begin
            ; If variable is defined, don't overwrite it.
            if (N_ELEMENTS(SCOPE_VARFETCH(varname, LEVEL=1)) gt 0) then $
                return, -1
        endif
    endif

    ; Store it
    (SCOPE_VARFETCH(varname, /ENTER, LEVEL=1)) = value

    return, 1

end

;;---------------------------------------------------------------------------
;; IDLitsrvCommandLine::ExportDataToCL
;;
;; Purpose:
;;  Given a parameter descriptor and visualization, export
;;  the given parameter to the command lines.
;;
;; Parameters:
;;    oData      - The data object to export
;;
;;    strname    - Name template to use
;;
;;
function IDLitsrvCommandLine::ExportDataToCL, oData, strName
  ;; Pragmas
  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    return, 0
  endif

  ;; Get all of the components for the data container
  IF (obj_isa(oData, "IDLitDataContainer")) && $
    ~obj_isa(oData,'IDLitDataIDLImagePixels') then begin
    ;; Okay we have multiple items to deal with.
    strData = oData->FindIdentifiers(/LEAF_NODES)
    strExVars = strarr(n_elements(strData))
    for i=0, n_elements(strData)-1 do begin
      status= oData->GetData(value, strData[i])
      if(status ne 0)then begin
        strExVars[i] = IDL_ValidName(strName, /convert_all)
        status = self->_InjectIDLVariable( strExVars[i], value)

        ;; check if the variable exists.
        if(status eq -1)then begin
          status = self->PromptUserYesNo(title=IDLitLangCatQuery('Error:OverwriteVariable:Title'), $
                                         [IDLitLangCatQuery('Error:OverwriteVariable:Text') + $
                                          strExVars[i] +"?"], answer)
          if(status ne 0 && answer eq 1)then $
            status = self->_InjectIDLVariable( strExVars[i], value, /overwrite)
        endif
        value=0
        if(status ne 1)then $
          break
      endif
    endfor
  endif else if obj_valid(oData) then begin
    status= oData->GetData(value)

    if(status ne 0)then begin
      oData->GetProperty, name=dataname
      strExVars= IDL_ValidName(strName,/convert_all)
      status = self->_InjectIDLVariable( strExVars, value)

      ;; Should we prompt the user for a go ahead?
      if(status eq -1)then begin
        status = self->PromptUserYesNo(title=IDLitLangCatQuery('Error:OverwriteVariable:Title'), $
                                         [IDLitLangCatQuery('Error:OverwriteVariable:Text') + $
                                          strExVars +"?"], answer)
        IF status NE 0 THEN status = answer EQ 1 ? $
          self->_InjectIDLVariable( strExVars, value,/overwrite) : 2
      ENDIF
      value=0
    endif
  end

  return, status
end
;;---------------------------------------------------------------------------
;; IDLitsrvCommandLine::_GetShapeString
;;
;; Purpose:
;;   Returns a data "shape" string that describes the provided
;;   variable.
;;
;; Parameters:
;;   vInfo - A variable information structure from the size() function
;;
;; Return Value:
;;;  The string to display

function IDLitsrvCommandLine::_GetShapeString, vInfo

    compile_opt idl2, hidden

    if(vInfo.n_elements le 1)then $
       return, "SCALAR"

    return, vInfo.type_name+"[" + string( vInfo.Dimensions[0:vInfo.n_dimensions-1], $
                                  format="(8( i0,:, ',' ))") + "]"
end


;;---------------------------------------------------------------------------
;; IDLitSrvCommandLine::_GetTypeIcon
;;
;; Purpose:
;;   This routine is used to return an icon name that matches the
;;   given type.
;;
;; Parameters:
;;   iType   = The IDL integer type code
;;
;; Return Value:
;;   The name of the icon to use for this type
;;
function IDLitSrvCommandLine::_GetTypeIcon, iType
   compile_opt hidden, idl2

   ;; This is pretty simple.
   case iType of
       7:  return,    "text"
       8:  return,    "struct"
       10: return,   "pointer"
       else: return, "vector"
   endcase

end


;;---------------------------------------------------------------------------
;; Descriptor creation section.
;;
;; This section of code is used to create a tree heirarchy that
;; represents the contents of the IDL command line. This structure
;; will "walk" structures and pointers to provide depth to the
;; heirarchy and enable an easy method to identify and use items from
;; the IDL command line.
;;---------------------------------------------------------------------------
;; IDLitSrvCommandLine::_CreateStructDescriptor
;;
;; Purpose:
;;   When creating a hierarchy for the command line, this method will
;;   build the descriptor for a structure.
;;
;; Parameters:
;;    data    - The current data element. This is a structure.
;;
;;    strDesc - The "reference" syntax for this element. This is
;;              used to build up the data access syntax as the
;;              hierarchy is built.
;;
;; Return Value:
;;    The descriptors for the tags that were created.

function IDLitSrvCommandLine::_CreateStructDescriptor, data, strDesc
    compile_opt hidden, idl2

    ;; Get the tags for this data and recurse of them.

    strTags = tag_names(data)
    nTags = n_elements(strTags)
    oTags = objarr(nTags)
    for i=0, nTags -1 do $
        oTags[i] = self->_CreateVariableDescriptor(data.(i), strTags[i], $
                                                   strDesc+"."+strTags[i])
    ;; return the tags
    return, oTags
end


;;---------------------------------------------------------------------------
;; IDLitsrvCommandLine::_CreateVariableDescriptor
;;
;; Purpose:
;;   This method is part of the logic to create a object hiearchy out
;;   of the contents of the command line. Given the current data item,
;;   this routine will build a data structure that encapsulates the
;;   data and any sub-items it might have.
;;
;; Parameters:
;;   data     - The current data item.
;;
;;   strName  - Name of the data item
;;
;;   strDesc  - The "reference" syntax for this element. This is
;;              used to build up the data access syntax as the
;;              hierarchy is built.
;;
;; Return Value:
;;    The descriptor created for the given data.

function IDLitSrvCommandLine::_CreateVariableDescriptor, data, strName, $
                            strDesc

    compile_opt hidden, idl2

    ;; Take the given data and build a description of it.
    if(n_elements(data) eq 0)then return, obj_new()

    sData = size(data,/structure, /L64)

    ;; If this is a struct or pointer, we recurse
    if(sData.type eq 10 or sData.type eq 8)then begin
        oVar = obj_new("IDLitCLitemContainer", NAME=strName, $
                       DESCRIPTION=strDesc, $
                       TYPE_NAME=sData.type_name, TYPE_CODE=sData.type, $
                       ICON=self->_GetTypeIcon(sData.type)) ;;
        ;; Handle arrays.
        nData = n_elements(data)
        for i=0, nData-1 do begin
            ;; create index into array
            index= (nData gt 1 ?  "["+strtrim(i,2)+"]" : "")
            if(sData.type eq 10)then begin ;; pointer
                ;; Add decoration for array indexing
                name = "(*"+strName + index + ")"
                desc = "(*"+strDesc+ index + ")"
                oVar->Add, self->_CreateVariableDescriptor( *data[i], name, desc)
            end else begin
                ;; We are processing a structure. This can be
                ;; complicated. If this is an array, we add a "extra"
                ;; level of descriptors. While a special case, the
                ;; results present better.
                desc = strDesc+index
                oStruct= self->_CreateStructDescriptor(data[i], desc)
                if(nData gt 1)then begin ;array?
                    oElement = obj_new("IDLitCLItemContainer", NAME=strName+index, $
                                       DESCRIPTION=desc, $
                                       TYPE_NAME=sData.type_name, TYPE_CODE=sData.type, $
                                       ICON=self->_GetTypeIcon(sData.type))
                    oElement->Add, oStruct ;; Add struct to Element
                    oVar->Add, oElement ;; Add element to the variable
                endif else $
                  oVar->Add, oStruct
            endelse

        endfor
    endif else if(sData.type eq 11 && obj_isa(data, "IDLgrComponent"))then begin
        ;; We have a object graphics item
        ;; Normal data
        oVar = obj_new("IDLitCLItem", NAME=strName, $
                       DESCRIPTION=strDesc, $
                       TYPE_NAME=obj_class(Data), TYPE_CODE=sData.type+10, $
                       SHAPE=self->_GetshapeString(sData), $
                       ICON=self->_GetTypeIcon(sData.type), $
                       data_type="IDLGROBJECT")
    endif else begin
        ;; Get the data types for this data. Note, the first entry
        ;; should be the primary/default type.
        dims = SIZE(Data, /DIMENSIONS)

        case SIZE(data, /N_DIMENSIONS) of

            1: begin
                ; Vector or connectivity array.
                types = ['IDLVECTOR', 'IDLCONNECTIVITY']
               end

            2: begin
                types = 'IDLARRAY2D'
                ; Column vector or 2D array.
                if (dims[0] eq 1) then $
                    types = ['IDLVECTOR', types]
                ; 2D array or vertices.
                if (dims[0] eq 2 || dims[0] eq 3) then $
                    types = [types, 'IDLVERTEX']
                ; 2D array or palette.
                if (dims[0] eq 3) then $
                    types = [types, 'IDLPALETTE']
               end

            3: begin
                types = 'IDLARRAY3D'
                ; Look for RGB or RGBA images.
                dex = where(dims eq 3 or dims eq 4, nMatch)
                if (nMatch gt 0) then $
                    types = ['IDLIMAGEPIXELS', types]
            end

            else: types='IDLARRAY'

        endcase

        ;; Normal data
        oVar = obj_new("IDLitCLItem", NAME=strName, $
                       DESCRIPTION=strDesc, $
                       TYPE_NAME=sData.type_name, TYPE_CODE=sData.type, $
                       SHAPE=self->_GetshapeString(sData), $
                       ICON=self->_GetTypeIcon(sData.type), $
                       data_type=types)
    endelse

    return, oVar
end


;;---------------------------------------------------------------------------
;; IDLitSrvCommandLine::GetCLVariableDescriptors
;;
;; Purpose:
;;    Return a hiearchy of components that describe the data layout of
;;    the IDL command line. This is normally a flat list, but will
;;    contain depth, if a pointer of structure exists at the command
;;    line.
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;    count   - The number of items returned
;;
;; Return Value
;;  A object heiarchy that represent the contents of the command
;;  line. The return objects should be returned to this service when
;;  they are no longer needed. This is done via the
;;  ReturnCLDescriptors method.
;;

function IDLitsrvCommandLine::GetCLVariableDescriptors, count=nNames
   compile_opt idl2, hidden

    strNames = SCOPE_VARNAME(LEVEL=1, COUNT=nNames)

    ;; Nothing contained
    if(nNames eq 0)then $
        return, obj_new()

    ;; Make the root container for the command line
    oRoot = obj_new("IDLitCLItemContainer", name="IDL Variables",$
                    icon="commandline", IDENTIFIER="")

    ;; Now we need to go through and process each variable. Basically
    ;; we recurse on the processing routine.
    for i=0, nNames-1 do begin
        ;; check to make sure the variable isn't undefined
        if (N_ELEMENTS(SCOPE_VARFETCH(strNames[i], LEVEL=1)) gt 0) then begin
            ; Pass the SCOPE_VARFETCH in directly without creating
            ; a temporary variable. This is fine because
            ; _CreateVariableDescriptor won't modify it.
            oItem = self->_CreateVariableDescriptor( $
                SCOPE_VARFETCH(strNames[i], LEVEL=1), $
                strNames[i], strNames[i])
            oRoot->Add, oItem
        endif
    endfor
    return, oRoot
end
;;---------------------------------------------------------------------------
;; IDLitsrvCommandLine::ReturnCLDescriptors
;;
;; Purpose:
;;   Method called to return any command line descriptors generated by
;;   this service
;;
;; Parameters:
;;    oDesc   - The returned descriptors
;;
pro IDLitsrvCommandLine::ReturnCLDescriptors, oDesc
    compile_opt hidden, idl2

    ;; not much here.
    if(obj_valid(oDesc))then obj_destroy, oDesc

end
;;---------------------------------------------------------------------------
;; IDLitsrvCommandLine::_GetSubDataItem
;;
;; Purpose:
;;   This method is used as part of the data import methodology to
;;   walk the given hiearchy and import data from a specific
;;   item. This method is used to access structure fields and
;;   pointers.
;;
;; Parameters:
;;   Value     - The current data value
;;
;;   oCurrent  - The current descriptor
;;
;;   id        - The current identifier of the item being located.
;;
;;   dataOut[out] - The data retrieved.
;;
;; Return Value
;;     0 - Error
;;     1 - Success
;;
function IDLitsrvCommandLine::_GetSubDataItem, value, oCurrent, id, dataOut
    compile_opt hidden, idl2

@idlit_catch
   if(iErr ne 0)then begin
       catch,/cancel
       return, 0
   endif

   ;; get the identifier of the next item to retrieve from the tree.
   strItem = IDLitBaseName(id, remainder=strRemain, /reverse)

   ;; Now get this value from the current level. Normally we would
   ;; just use GetByIdentifier, but we might need to know the position in
   ;; the container so pointer and struct arrays are handled
   ;; correctly.
   oCurrent->GetProperty, IS_ARRAY=isArray
   oItems = oCurrent->Get(/ALL, COUNT=nItems)
   if(isArray)then begin
       for i=0, nItems-1 do begin
           if(not obj_valid(oItems[i]))then begin ;; TODO: KDB REVIEW LOGIC
               continue
           endif
           oItems[i]->GetProperty, IDENTIFIER=strTmp
           if(strcmp(strItem, strTmp, /fold_case) ne 0)then begin
               ;; This is the item
               index = i
               break            ;
           endif
       endfor
       if(n_elements(index) eq 0)then return, 0
   endif else $
     index=0

   dataIn = value[index] ;; if we are an array.
   iType = size(dataIn,/type)

   ;; Okay, what type is this item we are working on?
   if (iType eq 8) then begin
        ; We need to index into the struct fields.
        ; Basically, get the next item, find a tag match and continue
        strTags = tag_names(dataIn)
        dex = (where(strItem eq strTags, nMatch))[0]
        if (~nMatch) then $
            return, 0
        ; Get the index field.
        dataIn = dataIn.(dex)
        if(strRemain ne '')then begin
            ; Recurse. The index into our oItems should match our
            ; structure tag index.
            return, self->_GetSubDataItem(dataIn, oItems[dex], $
                                       strRemain, dataOut)
        endif
   endif else if (iType eq 10) then begin
       dataIn = *dataIn ;; Dereference
       if (strRemain ne '') then begin
         return, self->_GetSubDataItem(dataIn, oItems[index], $
                                       strRemain, dataOut)
       endif
   endif
   dataOut = temporary(dataIn)
   return, 1
end
;;---------------------------------------------------------------------------
;; IDLitsrvCommandLine::ImportToDMByDescriptor
;;
;; Purpose:
;;   Use a variable descriptor to import the data into the data
;;   manager.
;;
;; Parameters
;;   oRoot  - The root of a variable hiearchy that was created by this
;;            service (returned from GetCLVariableDescriptors).
;;
;;   oDesc  - The target item to import.
;;
;; Keywords:
;;   NAME   - The name for the new data object
;;
;;   DESCRIPTION - The description for the new data object.
;;
;;   identifier  - The id of the data that was imported.
;;
;; Return Value:
;;   0   - Error
;;   1  - Success

function IDLitsrvCommandLine::ImportToDMByDescriptor, oRoot, oDesc, $
                            NAME=NAME, DESCRIPTION=DESCRIPTION, $
                            identifier=identifier, DATA_TYPE=DATA_TYPE

    compile_opt hidden, IDL2

    ;; The plan is to do the following;
    ;;  - Walk the variable hiearchy, taversing the data layout until
    ;;    the item referenced by oDesc is located. This value is
    ;;    retrieved, placed in a data object and inserted into the DM.

    ;; Get the identifier for the descriptor.
    id = oDesc->GetFullIdentifier()

    ;; Get the first identifier from the id
    strItem = IDLitBaseName(id, remainder=strRemain, /reverse)

    if(strItem eq '')then return, 0
    ;; Find the item at the root of the tree.
    oChild = oRoot->GetByIdentifier(strItem)
    ;; Get the variables value. Validate first

    vAvailable = SCOPE_VARNAME(LEVEL=1, COUNT=nVars)
    if (nVars eq 0) then $
        return, 0
    dex = where(strItem eq vAvailable, nVars)
    if(nVars eq 0)then  return, 0

    ;; Get the value
    variable = SCOPE_VARFETCH(strItem, LEVEL=1)

    ;; If we have to traverse the variable value heirarchy (pointers
    ;; or structures), the data must be traversed.
    if(strRemain ne '')then begin
        if( self->_GetSubDataItem(variable, oChild, strRemain, data) eq 0)then $
          return, 0
        variable = data
    endif

    ;; Time to import!
    if(~keyword_set(DATA_TYPE))then begin ;; get the default
        oDesc->getProperty, data_type=data_type
        data_type = data_type[0]
    endif
    if(keyword_set(DATA_TYPE))then begin
        ;; This keys off the type names that were established
        ;; above. Ideally this would be dynamic.
        case DATA_TYPE of
            'IDLARRAY2D': oData = obj_new('IDLitDataIDLARRAY2D')
            'IDLARRAY3D': oData = obj_new('IDLitDataIDLARRAY3D')
            'IDLIMAGEPIXELS': oData = obj_new('IDLitDataIDLImagePixels')
            'IDLVECTOR': oData = obj_new('IDLitDataIDLVECTOR')
            'IDLGROBJECT': oData = obj_new('IDLitData', $
                TYPE='IDLGROBJECT', ICON='image')
            'IDLVERTEX': oData = obj_new('IDLitData', $
                TYPE='IDLVERTEX', ICON='segpoly')
            'IDLCONNECTIVITY': oData = obj_new('IDLitData', $
                TYPE='IDLCONNECTIVITY', ICON='segpoly')
            'IDLPALETTE': oData = obj_new('IDLitDataIDLPalette')
            ; This will handle all other cases.
            else: oData = obj_new('IDLitData', type=DATA_TYPE)
        endcase
    endif else begin ;; no type information...shouldn't happen, but added catch all
        case SIZE(variable, /N_DIMENSIONS) of
            2: oData = obj_new('IDLitDataIDLARRAY2D')
            3: oData = obj_new('IDLitDataIDLARRAY3D')
            1: oData = obj_new('IDLitDataIDLVector')
            else:oData = obj_new('IDLitData', type='IDLARRAY')
        endcase
    endelse
    if( oData->SetData(variable, /no_copy) eq 0)then begin
        obj_destroy,oData
        return, 0
    endif
    if(not keyword_set(name))then name=obj_class(oData)
    if(not keyword_set(DESCRIPTION))then $
      oDesc->GetProperty, SHAPE=description
    oData->SetProperty, description=description, name=name, identifier=name

    ;; Place this item in the data manager.
    oTool=self->GetTool()
    oTool->AddByIdentifier, "/DATA MANAGER", oData
    identifier=oData->GetFullIdentifier()

    return, 1
end


;;---------------------------------------------------------------------------
;; The following section implements the objects used to create the
;; variable descriptors used by this service. Since these are only
;; created by this service, they can live in the same file as the
;; service implementation.
;;
;; Basically there are two objects: An Item and an Item
;; container. These are just IDLitComponent and IDLitContainer classes
;; with some extra properties added by the _IDLitCLItem class.
;;
;;---------------------------------------------------------------------------
;; IDLitCLItem::Init
;;
;; Purpose:
;;    Constructor for the IDLitCLItem class.
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;    All are passed to IDLitcomponent and _IDLitCLItem
;;
;; Return Value:
;;    0 - error, 1 - oK
function IDLitCLItem::Init, _extra=_extra
    compile_opt hidden, idl2
    if(self->IDLitComponent::Init(_extra=_extra) ne 1)then return, 0

    void = self->_idlitCLitem::Init()

    self->_idlitCLItem::SetProperty, _extra=_extra

    return, 1
end
;;---------------------------------------------------------------------------
;; IDLitCLItem::Cleanup
;;
;; Purpose:
;;    Destructor of this class.

pro IDLitCLItem::Cleanup
    compile_opt hidden, idl2

    self->_IDLitClItem::cleanup
    self->IDLitComponent::cleanup

end
;---------------------------------------------------------------------------
;; _IDLItCLItem::Init
;;
;; Purpose:
;;   Constructor for the item class.

function _IDLitCLItem::Init
    compile_opt hidden, idl2

    self._pTypes = ptr_new('')
    return,1
end
;;---------------------------------------------------------------------------
;; IDLitCLItem::Cleanup
;;
;; Purpose:
;;    Destructor of this class.
pro _IDLitCLItem::Cleanup
     compile_opt hidden, idl2

     ptr_free, self._ptypes

end
;;---------------------------------------------------------------------------
;; IDLitCLItem::Init
;;
;; Purpose:
;;    Constructor for the IDLitCLItemContainer class.
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;    All are passed to IDLitContainer and _IDLitCLItem
;;
;; Return Value:
;;    0 - error, 1 - oK
function IDLitCLItemContainer::Init, _extra=_extra
    compile_opt hidden, idl2
    if(self->IDLitContainer::Init(_extra=_extra) ne 1)then return, 0

    void = self->_IDLitClItem::Init()
    self->_idlitCLItem::SetProperty, _extra=_extra

    return, 1
end
;;---------------------------------------------------------------------------
pro IDLitCLItemContainer::Cleanup
    compile_opt hidden, idl2

    self->_IDLitClItem::cleanup
    self->IDLitContainer::cleanup

end
;;---------------------------------------------------------------------------
;; IDLitCLItem::GetProperty
;;
;; Purpose:
;;   Get properties from the class. This just routes calls to the
;;   superclasses of this class
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;   All those accepted by it's superclasses.
;;
pro idlitclItem::GetProperty, _REF_EXTRA=_extra
    compile_opt hidden, idl2
    self->IDLitComponent::GetProperty, _extra=_extra
    self->_IDLitCLItem::GetProperty, _extra=_extra
end
;;---------------------------------------------------------------------------
;; IDLitCLItem::SetProperty
;;
;; Purpose:
;;   Set properties on the class. This just routes calls to the
;;   superclasses of this class
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;   All those accepted by it's superclasses.
;;
pro idlitclItem::SetProperty, _EXTRA=_extra
    compile_opt hidden, idl2
    self->IDLitComponent::SetProperty, _extra=_extra
    self->_IDLitCLItem::SetProperty, _extra=_extra
end
;;---------------------------------------------------------------------------
;; IDLitCLItemContainer ::GetProperty
;;
;; Purpose:
;;   Get properties from the class. This just routes calls to the
;;   superclasses of this class
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;   All those accepted by it's superclasses.
;;
pro idlitclItemContainer::GetProperty, _REF_EXTRA=_extra
    compile_opt hidden, idl2
    self->IDLitContainer::GetProperty, _extra=_extra
    self->_IDLitCLItem::GetProperty, _extra=_extra
end
;;---------------------------------------------------------------------------
;; IDLitCLItemContainer::SetProperty
;;
;; Purpose:
;;   Set properties on the class. This just routes calls to the
;;   superclasses of this class
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;   All those accepted by it's superclasses.
;;
pro idlitclItemContainer::SetProperty, _EXTRA=_extra
    compile_opt hidden, idl2
    self->IDLitContainer::SetProperty, _extra=_extra
    self->_IDLitCLItem::SetProperty, _extra=_extra
end
;;---------------------------------------------------------------------------
;; _IDLitCLItem::SetProperty
;;
;; Purpose:
;;   Implements the set method for the properites of this class.
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;  TYPE_CODE     - The IDL type code for this item
;;
;;  TYPE_NAME     - The IDL type name for this item.
;;
;;  SHAPE         - The IDL shape string for this item.
;;
;;  IS_ARRAY      - Set if this item is an array.
;;
pro _IDLitCLItem::SetProperty, TYPE_CODE=TYPE, TYPE_NAME=TYPE_NAME, $
                SHAPE=SHAPE, IS_ARRAY=IS_ARRAY, DATA_TYPES=DATA_TYPES
   compile_opt hidden, idl2
   if(n_elements(type) ne 0)then self._itype=type
   if(n_elements(type_name) ne 0 )then self._type=type_name
   if(n_elements(is_array) ne 0)then self._array=is_array
   if(n_elements(shape) ne 0)then self._shape=shape
   if(n_elements(data_types) ne 0)then *self._pTypes = data_types


end
;;---------------------------------------------------------------------------
;; _IDLitCLItem::GetProperty
;;
;; Purpose:
;;   Implements the get method for the properites of this class.
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;  TYPE_CODE     - The IDL type code for this item
;;
;;  TYPE_NAME     - The IDL type name for this item.
;;
;;  SHAPE         - The IDL shape string for this item.
;;
;;  IS_ARRAY      - Set if this item is an array.
;;
pro _IDLitCLItem::GetProperty, TYPE_CODE=TYPE, TYPE_NAME=TYPE_NAME, $
                SHAPE=SHAPE, IS_ARRAY=IS_ARRAY, _EXTRA=_EXTRA, $
                DATA_TYPES=DATA_TYPES
   compile_opt hidden, idl2

   if(arg_present(type))then type = self._itype
   if(arg_present(type_name))then type_name = self._type
   if(arg_present(is_array))then is_array = self._array
   if(arg_present(shape))then shape= self._shape
   if(arg_present(data_types))then data_types = *self._pTypes
end

;-------------------------------------------------------------------------
;; Class definition

pro IDLitsrvCommandLine__define
    compile_opt idl2, hidden

    ;; Define the service. Just inherit from operation
    struc = {IDLitsrvCommandLine,            $
             inherits IDLitOperation}

    ;; define a struct to stash information
    void = {_IDLitSrvCommandline_, type:'', itype:0,  shape:'', isArray:0}

    ;; Define our classes used to build variable descriptions.
    void = {_IDLitCLItem, $
            _type :  '', $
            _shape : '', $
            _itype : '', $
            _pTypes: ptr_new(), $
            _array : ''}
    void = {IDLitCLItem, inherits _IDLitCLItem, inherits IDLitComponent}

    void = {IDLitCLItemContainer, inherits _IDLitCLItem, inherits IDLitContainer}
end

